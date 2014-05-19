/** 
 * Similiarly to parseInt/parseFloat, but can also handle binary
 *  numbers indicated by the "0b" prefix. If no prefix in combination
 *  with a decimal point "." is used, the number is interpret as float.
 */
function parseNum(str) {
   if(typeof(str) == 'number') return str;
   
   str = str.trim().toLowerCase();
   var result = 0;
   if (str.substr(0,2) == "0b") {
      for(var i=2; i<str.length; i++) {
         result <<= 1;
         if (str[i] == "1") {
            result += 1;
         } else if (str[i]) {
            return 0;
         }
      }
   
      return result;
   }
   
   return str.match(/\./) ? parseFloat(str) : parseInt(str, str.match(/^\s*0x/) ? 16 : 10);
}

/**
 * Takes a slice expresion in the following formats:
 *  - register
 *  - register.slice
 *  - register.slice[bit]
 * and returns an hash with the keys
 *  'reg', 'slice', 'bit', 'exp'.
 * If a property is not given by the expression, the
 * corresponding value in the hash is set to undefined */
function parseSlice(slice) {
   var m = slice.match(/^(.+)\.([^\[]+)(\[\d+\]|)$/);
   if (!m) return {
      'reg': slice,
      'slice': undefined,
      'bit': undefined,
      'exp': slice
   };
   return {
      'reg': m[1],
      'slice': m[2],
      'bit': m[3] ? parseInt(m[3].substr(1, m[3].length - 2)) : undefined,
      'exp': slice
   };
}

function parseCallback(elem, func, fallback) {
   if (elem[func])
      return elem[func];
   
   if (elem.get(func))
      return elem[func] = eval(elem.get(func));
   
   return fallback ? fallback : id;
}

var CTS = new Class({
   Implements: [Events],
   defs: null,

   autoCommitInhibit: false,
   nameDB: {},
   
   currentData: {},
   dataUpdateConstantFor: 0,
   dataUpdateActive: true,
   
   initialize: function(defs, nameDB) {
      this.defs = defs;
      if (nameDB) {
         this.nameDB = nameDB;
         if (nameDB['cts-compiletime'] && this.nameDB['cts-compiletime'] != this.defs.properties.trb_compiletime) {
            $$('#nameDB-match-warning .old-date').set('text', timestamp2Date(this.nameDB['cts-compiletime']) + ' - ' +this.nameDB['cts-compiletime']);
            $$('#nameDB-match-warning .new-date').set('text', this.defs.properties.trb_compiletime);
            $('nameDB-match-warning').setStyle('display', 'block');
         }
      }
      this.monitorPrefix = 'monitor-' + this.defs.server.port + '/';

      this.renderTriggerChannels();
      this.renderCoins();
      this.renderTriggerInputs();
      this.renderPeriphTrigger();
      this.renderRegularPulsers();
      this.renderRandPulsers();
      this.renderCTSDetails();
      this.renderOutputMux();
      
      this.initAutoRates();
      this.initAutoUpdate();
      this.dataUpdate();
      
      $('rate-plot').set('src', this.monitorPrefix + 'plot.png');
      this.addEvent('dataUpdate', function() {
         $('rate-plot').set('src', $('rate-plot').get('src').split('?')[0] + "?" + new Date().getTime());
      });
      
      this.addEvent('dataUpdate', this.updateStatusIndicator.bind(this));
      //this.addEvent('dataUpdate', function() {$('eb_rr').set('disabled', !this.currentData.

      this.initEventBuilderRR();
      
      this.initAutoCommit();
      this.initSliceTitle();
   },
   
   readRegisters: function(regs, callback, formated) {
      var opts = {'onFailure':requestFailure, 'url': '/cts/cts.pl?' + (formated ? "format" : "read") + ',' + Array.from(regs).join(",")};
      if (callback) {
         opts['onSuccess'] = callback;
         return (new Request.JSON(opts)).send();
      } else {
         opts['async'] = false;
         return (new Request.JSON(opts)).send().response.json;
      }
   },
   
   
   writeRegisters: function(values) {
      var arrValues = [];
      Object.each(values, function(v,r) {arrValues.push(r); arrValues.push(v)});
      (new Request.JSON({
         url: '/cts/cts.pl?write,' + arrValues.join(','),
         onSuccess: function(json, text) {
            if (!json) {
               var m = text.match(/<pre>(.*)<\/pre>/i);
               
               if (m) alert("Server send error response:\n"+m[1]);
               else  alert("An unknown error occured while writing register");
            }
         },
         onFailure: requestFailure
      })).send();
   },
   
   /**
    * Initially called by the class's constructor, this method
    * fetches the current monitoring snapshot from the server.
    * If successful, the event 'dataUpdate' is fired. The only
    * argument passed to the listeners is the current data. 
    * Alternatively a copy of the hash is stored in this.currentData.
    * 
    * The process can be paused by setting this.dataUpdateActive to
    * false. In this case the function polls every second and continues
    * fetching as soon as the this.dataUpdateActive is true again.
    * 
    * DO NOT CALL THIS METHOD MANUALLY !!! */
   dataUpdate: function() {
//       return;
      if (!this.dataUpdateActive) {
         this.dataUpdate.delay(1000, this);
         return;
      }
      
      var dup = $('data-update');
      dup.removeClass('error').set('text', 'Update').setStyle('display', 'block');
      
      // hard-reset. if request's timeout fails, this is the last resort ...
      var manualTimeout = (function(e) {
        window.location.reload();
      }).delay(10000, this, new Error());
      
      new Request.JSON({
         url: this.monitorPrefix + 'dump.js',
         timeout: 200,
         onSuccess: function(data) {
            window.clearTimeout(manualTimeout);
            if (parseInt(data.interval)) 
               this.dataUpdate.delay(parseInt(data.interval) + 200, this);
            else   
               this.dataUpdate.delay(1000, this);

            dup.setStyle('display', 'none');

            if (this.currentData.time == data.time) {
               this.dataUpdateConstantFor += 1;
               if (this.dataUpdateConstantFor > 2) {
                  dup.set('html', 'No change of timestamp since ' + this.dataUpdateConstantFor + ' fetches.<br />Server-Timestamp: ' + data.servertime).setStyle('display', 'block');
                  $('status-indicator').set('class', 'error');
                  return;
               }
                  
            } else {
               this.dataUpdateConstantFor = 0;
            }
            
            if (this.defs.properties.trb_endpoint != data.endpoint) {
               dup.set('text', 'Data from incompatible endpoint: 0x' + parseInt(data.endpoint).toString(16)).addClass('error').setStyle('display', 'block');
               $('status-indicator').set('class', 'error');
               return;
            }

            this.currentData = data;
            this.autoCommitInhibit = true;
            this.fireEvent('dataUpdate', data);
            this.autoCommitInhibit = false;
         }.bind(this),
                       
         onError: function(text, error) {
            window.clearTimeout(manualTimeout);
            this.dataUpdate.delay(100, this);
            dup.addClass('error').set('text', 'Update Decode Error').setStyle('display', 'block');
            $('status-indicator').set('class', 'error');
            if (console) console.log('Update Decode Error');
         }.bind(this),
            
         onFailure:    function(xhr) {
            window.clearTimeout(manualTimeout);
            this.dataUpdate.delay(1000, this);
            dup.addClass('error').set('text', 'Update Request Error').setStyle('display', 'block');
            $('status-indicator').set('class', 'error');
            if (console) console.log('Update Request Error');
         }.bind(this)
      }).send();
   },
   
   initEventBuilderRR: function() {
      if (!this.defs.properties.cts_eventbuilder_rr) {
	 $$('.eventbuilder_rr').destroy();
      } else {
	 $$('.eventbuilder_rr').setStyle('visibility', 'visible');
      }
   },

/**
 * This method handles all "autorate"-elements. It is registered
 * as an event listener to the 'dataUpdate' event and hence is automatically
 * invoked as soon as new data is available
 *
 * You dont need to call this method manually.
 */
   initAutoRates: function() {
      this.autoRateElems = $$('.autorate');
      this.addEvent('dataUpdate', function(data) {
         this.autoRateElems.each(function(e) {
            if (undefined == data.rates[ e.get('slice') ]) return;
	    if (e.hasClass('autoratevalue')) {
               var count = data.rates[ e.get('slice') ].value;
               
               count = parseCallback(e, 'format')(count);
               
               var prefix = e.get('prefix');
               if (prefix == null) prefix = "";
               var suffix = e.get('suffix');
               if (suffix == null) suffix = "";
               
               e.set('html', prefix + count + suffix);
            } else {
               var rate = data.rates[ e.get('slice') ].rate;
               
               rate = parseCallback(e, 'format', formatFreq)(rate);
               
               var prefix = e.get('prefix');
               if (prefix == null) prefix = "";
               var suffix = e.get('suffix');
               if (suffix == null) suffix = "";               
               
               e.set('html', prefix + rate + suffix);
            }
         });
      }.bind(this));
   },

/**
 * This method handles all "autoupdate"-elements. It is registered
 * as an event listener to the 'dataUpdate' event and hence is automatically
 * invoked as soon as new data is available
 *
 * You dont need to call this method manually.
 */
   initAutoUpdate: function() {
      this.autoUpdateElems = $$('.autoupdate');
      this.addEvent('dataUpdate', function(data) {
         this.autoUpdateElems.each(function(e) {
            if (parseInt(e.get('inhibitUpdate'))) {
               e.set('inhibitUpdate', parseInt(e.get('inhibitUpdate')) - 1);
               return;
            }
            if (e.focussed) return;
            var s = parseSlice(e.get('slice'));
            if (!s.slice) s.slice = "_compact";
         
            if (undefined == data.monitor[s.reg]) return;
				   
            var value = data.monitor[s.reg][e.get('type') == 'checkbox' || s.bit != undefined || e.hasClass('autoupdate-value') ? 'v' : 'f'][s.slice];
            if (s.bit != undefined) value = (parseInt(value) >> s.bit) & 1;
                                 
            if (e.format || e.get('format')) {
               value = parseCallback(e, 'format')(value, data.monitor[s.reg], e)
            } else if (value.replace) {
               value = value.replace(/, /g, ',<br />')
            }
                                   
            if (e.get('type') == 'checkbox') {
               e.set('checked', value ? 'checked' : '');
            } else {
               var prefix = e.get('prefix');
               if (prefix == null) prefix = "";
               var suffix = e.get('suffix');
               if (suffix == null) suffix = "";
               
               e.set(['input', 'select'].indexOf(e.get('tag')) >= 0 ? 'value' : 'html', prefix + value + suffix);
            }
         });
      });
   },

/**
 * This method handles all "autocommit"-elements. It is registered
 * as an event listener to all those elements and hence is automatically
 * invoked as soon as new data is available
 *
 * You dont need to call this method manually.
 */
   initAutoCommit: function() {
      var commit = function(evt) {
         if (this.autoCommitInhibit) return;
                                 
         var e = $(evt.target);
         var tmp = {};
         if (!e.hasClass('autocommit')) alert('Value cannot be commited');
   
         var s = parseSlice(e.get('slice'));

         var value = e.get('value');
         if (e.get('type') == 'checkbox')
            value = (e.get('checked') != "" ? '1' : '0');
            
         if (e.interpret || e.get('interpret')) {
            value = parseInt(Math.round( parseCallback(e, 'interpret')(value, e) ));
            
            if (e.format || e.get('format')) {
               if (e.get('type') == 'checkbox') 
                  e.set('checked', parseNum(parseCallback(e, 'format')(value, undefined, e)) ? 'checked' : '');
               else
                  e.set('value', parseCallback(e, 'format')(value, undefined, e));
            }
         }

         tmp[s.exp] = value;
         e.valueOnEnter = e.get('value');
         
         this.writeRegisters(tmp);
         e.removeClass('uncommitted');
         
         e.set('inhibitUpdate', 1);
      }.bind(this);
      
      $$('.autocommit').addEvents({
         'change': commit,
         'focus': function(e) {e.target.focussed = true; e.target.valueOnEnter = e.target.value;},
         'blur':  function(e) {e.target.focussed = false;},
         'keyup': function(e) {
            if (e.key == "enter")
               $(e.target).blur();
            else                
               $(e.target)[e.target.valueOnEnter == e.target.value ? 'removeClass' : 'addClass']('uncommitted');
         }
      });
   },

/**
 * Adds address information to the title of all elements with slice
 * attribute
 */
   initSliceTitle: function() {
      $$('*[slice]').each(function(e) {
         var s = parseSlice(e.get('slice'));
         var reg = this.defs.registers[s.reg];
         var bits = "";
         
         if (reg == undefined) {
            if (console) 
               console.debug("Register " + s + " not found. Please check definition of element ", e)
            return;
         }
         
         if (s.bit != undefined) {
            bits = ' Bit ' + (parseInt(reg._defs[s.slice].lower) + s.bit);
         } else if (s.slice) {
            bits = ' Bits ' + (parseInt(reg._defs[s.slice].lower) + parseInt(reg._defs[s.slice].len) - 1) + ':' + reg._defs[s.slice].lower;
         }

         e.set('title',
            s.exp + ': Address ' + formatAddress(reg._address) + bits
            + (e.get('title') ? ' \n' + e.get('title') : '')
         );
      }.bind(this));
   },
   
/**
 * Translate Names, such as channel assignments into user-overrideable values.
 */   
   
   translateName: function(category, key, def) {
      if (this.nameDB[category] == undefined)
         this.nameDB[category] = {};
      
      if (this.nameDB[category][key] == undefined)
         this.nameDB[category][key] = def;
      
      return def;
   },

/**
 * Creates all active elements of the AddOn Multiplexer Input Configuration
 * section. It is called by the class' constructor and hence
 * should not by called manually.
 */
   renderTriggerInputs: function() {
      var source_from = this.defs.properties.trg_input_count - this.defs.properties.trg_inp_mux_count;
      var to = this.defs.properties.trg_input_count;
      
      for(var i=0; i < to; i++) {
         var reg = 'trg_input_config' + i;
         var areg = 'trg_input_mux' + (i-source_from);
         var source;
         $('inputs-tab')
         .adopt(
            new Element('tr', {'class': i%2?'':'alt', 'flashgroup': 'itc-' + (i + parseInt(this.defs.properties.trg_input_itc_base))})
            .adopt([
               new Element('td', {'class': 'num', 'text': i}),
               
               (source = new Element('td', {'class': 'source'})),
               
               new Element('td', {'class': 'rate autorate', 'slice': 'trg_input_edge_cnt' + i + '.value', 'text': 'n/a', 'id': 'inp-rate' + i}),
               
               new Element('td', {'class': 'invert'}).adopt(
                  new Element('input', {'type': 'checkbox', 'class': 'autocommit autoupdate', 'slice': reg + '.invert'})
               ),

               new Element('td', {'class': 'delay'})
               .adopt([
                  new Element('input', {'class': 'text autocommit autoupdate', 'slice': reg + '.delay', 'format': 'countToTime', 'interpret': 'timeToCount'}),
                  new Element('span', {'text': ' ns'})
               ]),

               new Element('td', {'class': 'spike'})
               .adopt([
                  new Element('input', {'class': 'text autocommit autoupdate', 'slice': reg + '.spike_rej', 'format': 'countToTime', 'interpret': 'timeToCount'}),
                  new Element('span', {'text': ' ns'})
               ]),
               
               new Element('td', {'class': 'override'})
               .adopt(
                  new Element('select', {'class': 'text autocommit autoupdate', 'slice': reg + '.override'})
                  .adopt([
                     new Element('option', {'value': 'off', 'text': 'bypass'}),
                     new Element('option', {'value': 'to_low', 'text': '-> 0'}),
                     new Element('option', {'value': 'to_high', 'text': '-> 1'}),
                  ])
               )
            ])
         );
	 
         if (i >= source_from) {
            var en = this.defs.registers[areg]._defs.input.enum;
            keys = Object.keys(en);
            keys.sort(function(a,b) {return parseInt(a)-parseInt(b)});
            
            source.adopt(
               new Element('select', {'class': 'autocommit autoupdate', 'slice': areg + '.input'})
               .adopt(
                  keys.map(function (k) {
                     return new Element('option', {'value': en[k], 'text': this.translateName('addon-input-multiplexer', en[k], en[k])})
                  }, this)
               )
            );
         } else {
            source.set('text', 'hard wired');
         }
      }
   },
   
   renderOutputMux: function() {
      if (!this.defs.properties['trg_addon_output_mux_count']) {
         $('out-mux-expander').setStyle('display', 'none');
         return;
      }
      
      var con = $$('#out-mux-expander .content')[0];
      for(var i=0; i<this.defs.properties['trg_addon_output_mux_count']; i++) {
         var reg = 'trg_addon_output_mux' + i;
         var en = this.defs.registers[reg]._defs.input.enum;
         var name = this.defs.properties['trg_addon_output_mux_names'][i];
         keys = Object.keys(en);
         keys.sort(function(a,b) {return parseInt(a)-parseInt(b)});

         con.adopt(new Element('div', {'class': 'mux-container'}).adopt([
            new Element('label', {'for': 'out-mux-input' + i, 'text': this.translateName('addout-output-multiplexer', name, name)+": "}),
            new Element('select', {'id':  'out-mux-input' + i, 'slice': reg + '.input', 'class': 'autocommit autoupdate'}).adopt(
               keys.map(function (k) {return new Element('option', {'value': en[k], 'text': en[k]})})
            )
         ]));
      }
   },
   
   renderPeriphTrigger: function() {
      if (!this.defs.properties['trg_periph_count']) {
         $('periph-inp-expander').setStyle('display', 'none');
         return;
      }
      var tab = $('periph-inp-tab');
      var row, header;
      tab.adopt(header = new Element('tr', {'class': 'snd_header'}));
      header.adopt(new Element('td'));
      for(var f=0; f < 4; f++) {
         for(var i=4; i>=0; i--) {
            header.adopt(
               new Element('td', {'class': 'slice' + i}).adopt(
                  new Element('abbr', {'text': i-1, 'title': 'mapped to FPGA' + (f+1) + '_COMM(' + (i+6) + ')' + (i?'': ' - not accessible by most frontends')})
               )
            );
         }
      }
      
      for(var pt=0; pt < this.defs.properties['trg_periph_count']; pt++) {
         tab.adopt(row = new Element('tr', {'class': pt%2?'':'alt', 'flashgroup': 'itc-' + (pt + parseInt(this.defs.properties.trg_periph_itc_base))} ))
         row.adopt(new Element('td', {'text': pt, 'class': 'num'}));
         
         for(var f=0; f<4; f++) {
            for(var i=4; i>=0; i--) {
               var bit = (5*f + i);
                  row.adopt(new Element('td', {'class': 'slice' + i}).adopt(new Element('input', {
                     'class': 'autoupdate autocommit', 'type': 'checkbox',
                     'title': 'mapped to FPGA' + (f+1) + '_COMM(' + (i+6) + ')',
                     'slice': 'trg_periph_config' + pt + '.mask[' + bit + ']'})));
            }
         }
      }
      
   },
   
/**
 * Creates all active elements of the Trigger Channel Configuration
 * section. It is called by the class' constructor and hence
 * should not by called manually.
 */
   renderTriggerChannels: function() {
      for(var i=0; i < 16; i++) {
         if ("unconnected" == this.defs.properties.itc_assignments[i]) continue;
         var ddType, edgeType, assertedRate, edgeRate;
         $('itc-tab') // + (i / 8).toInt())
         .adopt(
            new Element('tr', {'class': i%2?'':'alt', 'flashgroup': 'itc-' + i})
            .adopt([
               new Element('td', {'text': i, 'class': 'channel'}),
               new Element('td', {'class': 'enable'})
               .adopt(
                  new Element('input', {'type': 'checkbox', 'id': 'itc-enable'+i, 'class': 'autocommit autoupdate', 'slice': 'trg_channel_mask.mask[' + i + ']'})
               ),

               new Element('td', {'class': 'edge'})
               .adopt(
                  edgeType = new Element('select', {'type': 'checkbox', 'class': 'autocommit autoupdate', 'slice': 'trg_channel_mask.edge[' + i + ']'})
                  .adopt([
                     new Element('option', {'value': '0', 'text': 'H. Level'}),
                     new Element('option', {'value': '1', 'text': 'R. Edge'})
                   ])
               ),
    
               itc = new Element('td', {'class': 'assign', 'text': this.translateName('itc-names', 'itc-' + i, this.defs.properties.itc_assignments[i])}),
               new Element('td', {'class': 'type'})
               .adopt(
                     ddType = new Element('select', {'class': 'autocommit autoupdate autoupdate-value', 'slice': '_trg_trigger_types' + (i < 8 ? '0' : '1') + '.type' + i})
               ),
   
               assertedRate = new Element('td', {'class': 'rate autorate', 'slice': 'trg_channel_asserted_cnt' + i + '.value', 'text': 'n/a', 'id': 'itc-asserted-rate' + i}),
               edgeRate = new Element('td', {'class': 'rate autorate', 'slice': 'trg_channel_edge_cnt' + i + '.value', 'text': 'n/a', 'id': 'itc-edge-rate' + i})
            ])
         );
	 
         for(var j=0; j < 16; j++)
            ddType.adopt(new Element('option', {'value': j, 'text': this.defs.registers['_trg_trigger_types' + (i < 8 ? '0' : '1')]._defs['type' + i].enum[j]}));
         
         edgeType.format = edgeType.interpret = function(x, y, t) {
            if (!t) t = y;
            x = parseInt(x) ? 1 : 0;
            var tds = t.getParent().getParent().getElements('td.rate');
            tds[x].addClass('active');
            tds[(x+1)%2].removeClass('active');
            
            return x;
         };
         
         assertedRate.format = rateToFrac;
      };
   },

/**
 * Creates all active elements of the Coincidence Detection Configuration
 * section. It is called by the class' constructor and hence
 * should not by called manually.
 */
   renderCoins: function() {
      $$("#coin-tab th.coin abbr, #coin-tab th.inhibit abbr").each(function(e){
         e.set("text", e.get('text').match(/^(.*)(\(.*\))?/)[1] 
            + " (" + (this.defs.properties.trg_input_count-1) + ":0)");
      }.bind(this));
      
      for(var i=0; i<this.defs.properties.trg_coin_count; i++) {
         var reg = 'trg_coin_config' + i;
         var coin, inhibit;
         $('coin-tab').adopt(
            new Element('tr', {'class': i%2?'':'alt', 'flashgroup':  'itc-' +  (i + parseInt(this.defs.properties.trg_coin_itc_base))})
            .adopt([
               new Element('td', {'class': 'num', 'text': i}),
               new Element('td', {'class': 'window'})
               .adopt([
                  new Element('input', {'class': 'autoupdate autocommit', 'slice': reg + '.window', 'format': 'countToTime', 'interpret': 'timeToCount'}),
                  new Element('span', {'text': ' ns'})
	       ]),
               coin = new Element('td', {'class': 'coin'}),
               inhibit = new Element('td', {'class': 'inhibt'})
	    ]) 
	 );
         
         for(var j=this.defs.properties.trg_input_count-1; j >= 0; j--) {
            coin.adopt(   new Element('input', {'type': 'checkbox', 'class': 'autoupdate autocommit', 'slice': reg+'.coin_mask['+j+']'}));
            inhibit.adopt(new Element('input', {'type': 'checkbox', 'class': 'autoupdate autocommit', 'slice': reg+'.inhibit_mask['+j+']'}));
         }
      }
   },
   
/**
 * Creates all active elements of the Regular Pulser
 * section. It is called by the class' constructor and hence
 * should not by called manually.
 */
   renderRegularPulsers: function() {
      var cnt = this.defs.properties.trg_pulser_count;
      if (!cnt) {
         $$('#pulser-expander .pulser-content').set('text', "This specific CTS design does not support regular pulsers");
         return;
      }
      
      var freqTD, durInp;
      
      var parsedInput = new Element('div', {'class': 'hint'}).inject($('content-area'), 'after');
      parsedInput.linkedTo = null;
      parsedInput.reposition = function() {
         if (!parsedInput.linkedTo) return;
         var refPos = parsedInput.linkedTo.getCoordinates();
         var piSize = parsedInput.getScrollSize();
         parsedInput.setStyles({'left': refPos.left + refPos.width + 5, 'top': refPos.top + refPos.height/2 - piSize.y/2});
         
         return this;
      };
      window.addEvent('resize', parsedInput.reposition);
      
      for(var i=0; i < cnt; i++) {
         $('pulser-tab').adopt(
            new Element('tr', {'class': i%2?'':'alt', 'flashgroup':  'itc-' + (i + parseInt(this.defs.properties.trg_pulser_itc_base))})
            .adopt(
               new Element('td', {'class': 'num', 'text': i})
            ).adopt(
               new Element('td', {'class': 'period'}).adopt(
                  durInp = new Element('input', {
                     'slice': 'trg_pulser_config' + i + '.low_duration',
                     'class': 'autoupdate autocommit',
                      'inputhint': 'Three input formats are supported:<br />' + 
                        '1.) Enter the <strong>duration of the low-period</strong> in clock cycles by <strong>omitting a unit</strong><br />' + 
                        '2.) Enter the <strong>duration of the low-period</strong> in seconds by adding "<pre>s</pre>"<br />'+
                        '3.) Enter the <strong>frequency</strong> by appending "<pre>Hz</pre>"<br /><br/>' + 
                        'Optional unit prefixes: <pre>n</pre>, <pre>u</pre>, <pre>m</pre>, <pre>k</pre>/<pre>K</pre>, <pre>M</pre>, <pre>g</pre>/<pre>G</pre>. Example 1ms = 1e-3s, 1 Ms = 1e3s<br />' +
                        'Press enter or leave input do apply values. This might take a few moments <br/>and is completed as soon as the left column has changed'
                  })
               )
            ).adopt(
               freqTd = new Element('td', {'class': 'freq autoupdate', 'slice': 'trg_pulser_config' + i + '.low_duration'})
            )
         );
         
         durInp.format = function(val) {
            val /= cts.defs.properties.cts_clock_frq;
            return appendScalingPrefix(val, val > 1e-6 ? 2 : 0) + 's';
         }.bind(this);
         
         durInp.interpret = function(val) {
            val = val.trim();
            if (!val) return 0;
            
            var matches;
         
          // frequency -> count
            if (matches = val.match(/((\d+)\s*[munkKMgG]?)[hH][zZ]?/)) {
               var freq = interpretScalingPrefix(matches[1]);
               return this.defs.properties.cts_clock_frq / freq - 1;
            }
            
          // time -> count
            if (matches = val.match(/((\d+|\d*\.\d+)\s*[munkKMgG]?)s/)) {
               var secs = interpretScalingPrefix(matches[1]);
               return secs * this.defs.properties.cts_clock_frq;
            }
            
          // counts
            return parseNum(val);
         }.bind(this);
         
         var updateParsedInput = function() {
            var inp = parsedInput.linkedTo;
            if (!inp) return;
                    
            var val = inp.interpret(inp.get('value'));
            parsedInput.set('text', rateToFrac(cts.defs.properties.cts_clock_frq / (1+parseInt(val)))).reposition();
         };
         
         durInp.addEvents({
            'focus': function(e) {
               var t = $(e.target);
               parsedInput.linkedTo = t;
               parsedInput.reposition().fade('in');
               updateParsedInput();
            },
               
            'blur': function() {
               parsedInput.fade('out').linkedTo = null;
            },
            
            'click': updateParsedInput,
            'keyup': updateParsedInput
         });
         
         freqTd.format = function(val) {
            return rateToFrac(cts.defs.properties.cts_clock_frq / (1+parseInt(val)))
         };
         
      }
   },

/**
 * Creates all active elements of the Pseudorandom Pulser
 * section. It is called by the class' constructor and hence
 * should not by called manually.
 */
   renderRandPulsers: function() {
      var cnt = this.defs.properties.trg_random_pulser_count;
      if (!cnt) {
         $$('#pulser-expander .content .pulser-content').set('text', "This specific CTS design does not support pseudorandom pulsers");
         return;
      }
      
      for(var i=0; i < cnt; i++) {
         var inp;
         $('rand-pulser-tab').adopt(
            new Element('tr', {'class': i%2?'':'alt', 'flashgroup':  'itc-' + (i + parseInt(this.defs.properties.trg_random_pulser_itc_base))})
            .adopt(
               new Element('td', {'class': 'num', 'text': i})
            ).adopt(
               new Element('td', {'class': 'freq'}).adopt(
                  inp = new Element('input', {
                     'slice': 'trg_random_pulser_config'+i+'.threshold',
                     'value': 'n/a',
                     'class': 'autocommit autoupdate',
                     'interpret': 'InterpretToRandPulserThreshold',
                     'format': 'FormatRandPulserThreshold',
                     'inputhint': 'Enter the <strong>mean frequency</strong> in Hz<br />' + 
                        'Optional unit prefixes: <pre>n</pre>, <pre>u</pre>, <pre>m</pre>, <pre>k</pre>/<pre>K</pre>, <pre>M</pre>, <pre>g</pre>/<pre>G</pre>. Example 1ms = 1e-3s, 1 Ms = 1e3s<br />' +
                        'Press enter or leave input do apply values. The changes might take a few moments<br /> and are visible in the corresponding ITC stats'

                  })
               )
            )
         );
      }
   },
   
   renderCTSDetails: function() {
      $('trb_compiletime').set('text', timestamp2Date(this.defs.properties.trb_compiletime));
      $('trb_endpoint').set('text', "0x" + this.defs.properties.trb_endpoint.toString(16));
      $('trb_daqopserver').set('text', this.defs.properties.daqopserver);
   },
   
   updateStatusIndicator: function(data) {
      var elem = $('status-indicator'), cls = 'error';
      var fullstop = $('fullstop').get('checked');
      
      if (data.rates['cts_cnt_trg_accepted.value'].rate > 0) {
         cls = 'okay';
      } else if (data.rates['cts_cnt_trg_asserted.value'].rate < 1 || fullstop) {
         if (data.monitor.cts_td_fsm_state.f.state == 'TD_FSM_IDLE') cls = 'warning';
      }
      
      elem.set('class', cls);
      
      if (cls == 'okay') {elem.set('title', 'CTS currently accepts triggers. Everything seems alright');}
      else if (cls=='warning') {elem.set('title', 'No events were accepted, but CTS seems ready.' + (fullstop ? ' Full Stop active!' : 'Maybe no events occured?'));}
      else {elem.set('title', 'CTS is neither idle, nor did it accept any events. Stuck at ' + 
         data.monitor.cts_td_fsm_state.f.state + ' and ' + data.monitor.cts_ro_fsm_state.f.state);}
   }
});

function timestamp2Date(ts) {
   return new Date(ts * 1000 - new Date().getTimezoneOffset() * 60000).toGMTString().replace('GMT', '');
}
   

function requestFailure(obj){
   var text = (obj.responseText) ? obj.responseText : obj;
   var m = text.match(/<pre>([\s\S]*)<\/pre>/im);
   
   
   if (obj.responseText && m) {
      text = m[1];
      m = text.match(/^\s*-+ More[\w\s]+ -+\s+(.+)$/im)
      if (m) text = m[1];
      
      alert("Server send error response:\n"+text.trim());
   } else {
      alert("An unknown error while contacting the sever. Did you open this file locally? Did the connection or server crash?\nHint:\n" + text);
   }
}

function loadCTS(nameDB) {
   if (typeOf(nameDB) != 'object')
      nameDB = {};

   (new Request.JSON({'url': 'cts.pl?init',
                     'onSuccess': function(json) {cts = new CTS(json, nameDB)},
                     'onFailure': requestFailure,
                     'onError': requestFailure})).send();   
}

(new Request.JSON({'url': 'names.json',
                   'onSuccess': loadCTS,
                   'onFailure': loadCTS,
                   'onError': loadCTS})).send();

function countToTime(val) {return (1.0*val / cts.defs.properties.cts_clock_frq * 1e9).toFixed(0);}
function countToFreq(val) {return formatFreq (1 / (val / cts.defs.properties.cts_clock_frq)); }
function timeToCount(val) {return (parseNum(val) / 1.0e9 * cts.defs.properties.cts_clock_frq).round();}
function rateToFrac(val) {return appendScalingPrefix(val) + 'cnt/s'}

function formatFreq(val, sigDigits) {
   return appendScalingPrefix(val, sigDigits) + "Hz";
}

function appendScalingPrefix(val, sigDigits) {
   var fac = 3;
   
   var pref = [1e-9, 'n', 1e-6, 'u', 1e-3, 'm',
               1e9,  'G', 1e6,  'M', 1e3,  'K'];
               
   if (sigDigits === undefined) sigDigits = 2;
   
   while(val && pref.length) {
      scale = pref.shift();
      name  = pref.shift();
   
      if (((scale > 1) && (val > scale * fac)) || ((scale < 1) && (val < scale * 100 * fac)))
         return ((val / scale).toFixed(sigDigits) + ' ' + name).replace(',', '.');
   }
   
   return val.toFixed(sigDigits) + ' ';
}

function interpretScalingPrefix(val) {
   var num = parseNum(val);
   val.trim();
   var prefs = {
      'n': 1e-9,
      'u': 1e-6,
      'm': 1e-3,
      'K': 1e3, 'k': 1e3,
      'M': 1e6,
      'G': 1e9, 'g': 1e9};
   
   var prefix = val.substr(val.length - 1, 1);
   
   if (prefs[prefix])
      num *= prefs[prefix];
   
   return num;
}

function InterpretToRandPulserThreshold(v) {
   var match = v.match(/((\d+|\d*\.\d+)\s*[munkKMgG]?)[hH]?[zZ]?/);
   if (!match) return 0;
   
   freq = interpretScalingPrefix(match[1]);
   
   freq = Math.min(cts.defs.properties.cts_clock_frq, Math.max(freq, 0));
   
   return Math.round(freq / cts.defs.properties.cts_clock_frq * 0x7FFFFFFF); 
};

function FormatRandPulserThreshold(v) {
   return formatFreq(Math.round(cts.defs.properties.cts_clock_frq * v / 0x7FFFFFFF), 0);
};      
  
function formatAddress(x) {
   var hex = parseNum(x).toString(16);
   while(hex.length < 4) hex = "0" + hex;
   return "0x" + hex;
}

window.addEvent('domready', function() {
   $('rate-plot').addEvent('click', function() {
      var i = $('rate-plot');
      u = i.get('src');
      if (u.test('short'))
         u = u.replace('short', '');
      else
         u = u.replace('plot.', 'plotshort.');
      
      i.set('src', u);
   });
});

var GuiExpander = new Class({
   boxes: null,
   states: {},
   
   initialize: function() {
      this.boxes = $$('div.expandable');
      if (!this.boxes) return;
                            
      var states = Cookie.read('GuiExpander.States');
      if (!states) states = {};
                            
      this.boxes.each(function(b) {
         var id = b.get('id');
         if (!id) {if (console) console.debug("Expandable Box without ID!"); return;}
         this[states[id] || b.hasClass('expanded') ? 'expand' : 'collapse'](b, true);

         
         $$("#" + id + " .content")[0].set('morph', {duration: 100, link: "chain"});
         $$("#" + id + " .header" )[0].addEvent('click', this.toggle.bind(this, id));
      }, this);
   },
   
   collapse: function(id, instantly, height) {
      if (id.get) id = id.get('id');
      if (!height) height = 0;

      var e = $$("#" + id + " .content")[0]; 
      var s = (height != 0);
      this.states[id] = s;

      var setEndpoint = function() {
         e.setStyles({"height": (height > 0 ? "" : "0"), "display": (height > 0 ? "block" : "hidden"), 'padding': (height ? '' : '0')});
      }
      
      if (instantly)
         setEndpoint();
      else {
         e.morph({'height': height});
         setEndpoint.delay(200);
      }
      
      $$("#" + id + " .indicator")[0].set('text', s ? "-" : "+");
      $(id)[s ? "addClass" : "removeClass"]('expanded');

   },
   
   expand: function(id, instantly) {
      if (id.get) id = id.get('id');
      var e = $$("#" + id + " .content")[0]; 

      this.collapse(id, instantly, e.getScrollSize().y);
   },
   
   toggle: function(id) {
      if (id.get) id = id.get('id');
      this[ this.states[id] ? "collapse" : "expand" ](id);
   },

   update: function(id) {
      if (!id) {
         this.boxes.each(function(b){
            this.update(b.get('id'));
         }.bind(this));
         return;
      }
         
      if (id.get) id = id.get('id');
      this[ !this.states[id] ? "collapse" : "expand" ](id);
   }
});
var guiExpander;
window.addEvent('domready', function() {guiExpander = new GuiExpander();});

/* InputHints */
/**
 * Shows a caption-like hint below an input field each time it gets the focus
 */
window.addEvent('load', function() {
   var inputs = $$('input[inputhint]');
   if (!inputs) return;
   
   var activeInput = null;
   
   var caption = new Element('div', {id: 'input-hint', 'class': 'hint'}).inject($('content-area'), 'after');
   caption.reposition = function() {
      if (!activeInput) return;
      
      var inputPos = activeInput.getCoordinates();
      var wndSize = document.getSize();
      var captionSize = caption.getScrollSize();
      
      caption.setStyles({
         'top': inputPos.top + inputPos.height + 3,
         'left': Math.max(0, Math.min(inputPos.left - 11, wndSize.x - captionSize.x))
      });
   };
   
   inputs.each(function(input) {
      if (input.get('inputhint-registered')) return;
               
      input.addEvents({
      'focus': function(e) {
         var t = $(e.target);
         activeInput = t;
         caption.set('html', t.get('inputhint'));
         caption.reposition();
         caption.fade('in');
      },
                  
      'blur': function() {
         caption.fade('out');
         activeInput = null;
      }
      }).set('inputhint-registered', '1');
   });
   
   window.addEvent('resize', caption.reposition);
});
   
/* Flash groups */
window.addEvent('load', function() {
   $$('*[flashgroup]').addEvents({
      'mouseenter': function(e) {
         var t = $(e.target);
         while(!t.get('flashgroup')) {
            if (t.get('id') == 'content-area') return;
            t = t.getParent();
         }
         
         $$('*[flashgroup="' + t.get('flashgroup') + '"]').addClass('flash');
      }, 
      
      'mouseleave': function(e) {
         $$('.flash').removeClass('flash');
      }
   });
});

function id(x) {return x;}


function prettyJSON(obj, indent){
   if (indent==undefined) indent="";
   if (obj && obj.toJSON) obj = obj.toJSON();

   switch (typeOf(obj)){
      case 'string':
         return '"' + obj.replace(/[\x00-\x1f\\"]/g, escape) + '"';
      case 'array':
         return '[' + obj.map(JSON.encode).clean() + ']';
      case 'object': case 'hash':
         var string = [];
         Object.each(obj, function(value, key){
            var json = prettyJSON(value, indent + '  ');
            if (json) string.push(prettyJSON(key) + ':  ' + json);
         });
         
         return string ? ('{\n' + indent + "  " + string.join(",\n  " + indent) + "\n" + indent + '}') : "{}";
      case 'number': case 'boolean': return '' + obj;
      case 'null': return 'null';
   }

   return null;
};


window.addEvent('domready', function() {
   $('gui_export_name_template').addEvent('click', function(e) {
      e.stop();
      cts.nameDB['cts-compiletime'] = cts.defs.properties.trb_compiletime;
      $$('#win-nameDB .template')[0].set('text', prettyJSON(cts.nameDB));
      $('win-nameDB').fade('hide').setStyle('display', 'block').fade('in');
   });
});
      
      
   
