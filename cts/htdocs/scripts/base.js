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
   
   currentData: {},
   dataUpdateConstantFor: 0,
   dataUpdateActive: true,
   
   initialize: function(defs) {
      this.defs = defs;

      this.renderTriggerChannels();
      this.renderTriggerInputs();
      this.renderCoins();
      this.renderRegularPulsers();
      this.renderRandPulsers();
      this.renderCTSDetails();
      
      this.initAutoRates();
      this.initAutoUpdate();
      this.dataUpdate();
      
      this.addEvent('dataUpdate', function() {
         $('rate-plot').set('src', $('rate-plot').get('src').split('?')[0] + "?" + new Date().getTime());
      });
      
      this.addEvent('dataUpdate', this.updateStatusIndicator.bind(this));
      
      this.initAutoCommit();
      
      this.initSliceTitle();
   },
   
   readRegisters: function(regs, callback, formated) {
      var opts = {'url': 'cts.pl?' + (formated ? "format" : "read") + ',' + Array.from(regs).join(",")};
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
      console.debug(values, arrValues);
      (new Request.JSON({
         url: 'cts.pl?write,' + arrValues.join(','),
         onSuccess: function(json, text) {
            if (!json) {
               var m = text.match(/<pre>(.*)<\/pre>/i);
               if (m) alert("Server send error response:\n"+m[1]);
               else  alert("An unknown error occured while writing register");
            }
         },
         onFailure: function(xhr){
               var m = xhr.responseText.match(/<pre>([\s\S]*)<\/pre>/im);
               if (m) alert("Server send error response:\n"+m[1].trim());
               else  alert("An unknown error occured while writing register");
         }
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
      if (!this.dataUpdateActive) {
         this.dataUpdate.delay(1000, this);
         return;
      }
      
      var dup = $('data-update');
      dup.removeClass('error').set('text', 'Update').setStyle('display', 'block');
      
      // hard-reset. if request's timeout fails, this is the last resort ...
      var manualTimeout = window.location.reload.delay(10000);
      
      new Request.JSON({
         url: 'monitor/dump.js',
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
            
         onFailure:    function() {
            window.clearTimeout(manualTimeout);
            this.dataUpdate.delay(1000, this);
            dup.addClass('error').set('text', 'Update failed').setStyle('display', 'block');
            $('status-indicator').set('class', 'error');
         }.bind(this)
      }).send();
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
            value = parseCallback(e, 'interpret')(value, e);
            
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
         
         if (s.bit != undefined) {
            bits = ' Bit ' + (parseInt(reg._defs[s.slice].lower) + s.bit);
         } else if (s.slice) {
            bits = ' Bits ' + (parseInt(reg._defs[s.slice].lower) + parseInt(reg._defs[s.slice].len) - 1) + ':' + reg._defs[s.slice].lower;
         }

         e.set('title',
            s.exp + ': Address ' + formatAddress(reg._address) + bits
            + (e.get('title') ? ' ' + e.get('title') : '')
         );
      }.bind(this));
   },
   
/**
 * Creates all active elements of the Trigger Input Configuration
 * section. It is called by the class' constructor and hence
 * should not by called manually.
 */
   renderTriggerInputs: function() {
      for(var i=0; i < this.defs.properties.trg_input_count; i++) {
         var reg = 'trg_input_config' + i;
         $('inputs-tab')
         .adopt(
            new Element('tr', {'class': i%2?'':'alt'})
            .adopt(
               new Element('td', {'class': 'num', 'text': i})
            ).adopt(
               new Element('td', {'class': 'rate autorate', 'slice': 'trg_input_edge_cnt' + i + '.value', 'text': 'n/a', 'id': 'inp-rate' + i})
            ).adopt(
               new Element('td', {'class': 'invert'})
               .adopt(
                  new Element('input', {'type': 'checkbox', 'class': 'autocommit autoupdate', 'slice': reg + '.invert'})
               )
            ).adopt(
               new Element('td', {'class': 'delay'})
               .adopt(
                  new Element('input', {'class': 'text autocommit autoupdate', 'slice': reg + '.delay', 'format': 'countToTime', 'interpret': 'timeToCount'})
               ).adopt(
                  new Element('span', {'text': ' ns'})
               )
            ).adopt(
               new Element('td', {'class': 'spike'})
               .adopt(
                  new Element('input', {'class': 'text autocommit autoupdate', 'slice': reg + '.spike_rej', 'format': 'countToTime', 'interpret': 'timeToCount'})
               ).adopt(
                  new Element('span', {'text': ' ns'})
               )
            ).adopt(
               new Element('td', {'class': 'override'})
               .adopt(
                  new Element('select', {'class': 'text autocommit autoupdate', 'slice': reg + '.override'})
                  .adopt(
                     new Element('option', {'value': 'off', 'text': 'bypass'})
                  ).adopt(
                     new Element('option', {'value': 'to_low', 'text': '-> 0'})
                  ).adopt(
                     new Element('option', {'value': 'to_high', 'text': '-> 1'})
                  )
               )
            )
         );
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
            new Element('tr', {'class': i%2?'':'alt'})
            .adopt(
               new Element('td', {'text': i, 'class': 'channel'})
            ).adopt(
               new Element('td', {'class': 'enable'})
               .adopt(
                  new Element('input', {'type': 'checkbox', 'id': 'itc-enable'+i, 'class': 'autocommit autoupdate', 'slice': 'trg_channel_mask.mask[' + i + ']'})
               )
            ).adopt(
               new Element('td', {'class': 'edge'})
               .adopt(
                  edgeType = new Element('select', {'type': 'checkbox', 'class': 'autocommit autoupdate', 'slice': 'trg_channel_mask.edge[' + i + ']'})
                  .adopt(
                     new Element('option', {'value': '0', 'text': 'H. Level'})
                   ).adopt(
                     new Element('option', {'value': '1', 'text': 'R. Edge'})
                   )
               )
            ).adopt(
               new Element('td', {'class': 'assign', 'text': this.defs.properties.itc_assignments[i]})
            ).adopt (
               new Element('td', {'class': 'type'})
               .adopt(
                     ddType = new Element('select', {'class': 'autocommit autoupdate autoupdate-value', 'slice': '_trg_trigger_types' + (i < 8 ? '0' : '1') + '.type' + i})
               )
            ).adopt (
               assertedRate = new Element('td', {'class': 'rate autorate', 'slice': 'trg_channel_asserted_cnt' + i + '.value', 'text': 'n/a', 'id': 'itc-asserted-rate' + i})
            ).adopt (
               edgeRate = new Element('td', {'class': 'rate autorate', 'slice': 'trg_channel_edge_cnt' + i + '.value', 'text': 'n/a', 'id': 'itc-edge-rate' + i})
            )
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
            new Element('tr', {'class': i%2?'':'alt'})
            .adopt(
               new Element('td', {'class': 'num', 'text': i})
            ).adopt(
               new Element('td', {'class': 'window'})
               .adopt(
                  new Element('input', {'class': 'autoupdate autocommit', 'slice': reg + '.window', 'format': 'countToTime', 'interpret': 'timeToCount'})
               ).adopt(
                  new Element('span', {'text': ' ns'})
            )).adopt(
               coin = new Element('td', {'class': 'coin'})
            ).adopt(
               inhibit = new Element('td', {'class': 'inhibt'})
         ));
         
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
      
      var regs = [];
      
      for(var i=0; i < cnt; i++) {
         $('pulser-tab').adopt(
            new Element('tr', {'class': i%2?'':'alt'})
            .adopt(
               new Element('td', {'class': 'num', 'text': i})
            ).adopt(
               new Element('td', {'class': 'period'}).adopt(
                  new Element('input', {'id': 'pulser-period'+i, 'value': 'n/a'})
               ).adopt(new Element('span', {'text': ' us'}))
            ).adopt(
               new Element('td', {'class': 'freq', 'id': 'pulser-freq'+i, 'text': 'n/a'})
            )
         );
         
         regs.push('trg_pulser_config' + i);
      }
      
      this.readRegisters(regs, function(data) {
         this.pulser_values = data;
         
         for(var i=0; i < cnt; i++) {
            $('pulser-period'+i).set('value', data['trg_pulser_config' + i].low_duration + 1);
            $('pulser-period'+i).addEvents({
               'change': this.updatePulser.bind(this, true),
               'blur': this.updatePulser.bind(this, true),
               'keyup': this.updatePulser.bind(this, false),
            });
         }
         
         this.updatePulser();
         
      }.bind(this));
   },
   
   updatePulser: function(store) {
      for(var i=0; i <  this.defs.properties.trg_pulser_count; i++){
         var elem = $('pulser-period'+i);
         var val = parseNum(elem.get('value'));
         
         var m = elem.get('value').toLowerCase().match(/([mk]?)hz/);
         if (m) {
            if (m[1] == 'k') val *= 1e3;
            if (m[1] == 'm') val *= 1e6;
                    
            val = Math.round ( 1e8 * (1/ val - 1/this.defs.properties.cts_clock_frq)  );
            if (store) elem.set('value', val);
         }
         
         var changed = (val != this.pulser_values['trg_pulser_config' + i].low_duration + 1);
         
         if (store && changed && !isNaN(val)) {
            var tmp = {};
            tmp['trg_pulser_config' + i + '.low_duration']
             = this.pulser_values['trg_pulser_config' + i].low_duration
             = Math.max(0, val - 1);
            this.writeRegisters(tmp);
            
            changed = false;
         }
         
         elem[changed ? 'addClass' : 'removeClass']('unsaved');
         $('pulser-freq'+i).set('text', (changed ? "(CTS not updated) " : "") + formatFreq(1 / (val / 1e8 + 1 / this.defs.properties.cts_clock_frq)));
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
            new Element('tr', {'class': i%2?'':'alt'})
            .adopt(
               new Element('td', {'class': 'num', 'text': i})
            ).adopt(
               new Element('td', {'class': 'freq'}).adopt(
                  inp = new Element('input', {
                     'slice': 'trg_random_pulser_config'+i+'.threshold',
                     'value': 'n/a',
                     'class': 'autocommit autoupdate',
                     'interpret': 'InterpretToRandPulserThreshold',
                     'format': 'FormatRandPulserThreshold'
                  })
               )
            )
         );
      }
   },
   
   renderCTSDetails: function() {
      $('trb_compiletime').set('text', new Date(this.defs.properties.trb_compiletime * 1000 - new Date().getTimezoneOffset() * 60000).toGMTString().replace('GMT', ''));
      $('trb_endpoint').set('text', "0x" + this.defs.properties.trb_endpoint.toString(16));
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

var cts;
(new Request.JSON({'url': 'cts.pl?init',
                   'onSuccess': function(json) {cts = new CTS(json)},
                   'onError': function() {alert("Error while fetching CTS definitions. Did you open this file locally???");}})).send();
   
function countToTime(val) {return (1.0*val / cts.defs.properties.cts_clock_frq * 1e9).toFixed(0);}
function countToFreq(val) {return formatFreq (1 / (val / cts.defs.properties.cts_clock_frq)); }
function timeToCount(val) {return (parseNum(val) / 1.0e9 * cts.defs.properties.cts_clock_frq).round();}

function formatFreq(val, sigDigits) {
   var fac = 3;
   
   if (sigDigits == undefined) sigDigits = 2;
   
        if (val < 0.1 * fac && val > 0) val = (val * 1000).toFixed(sigDigits) + " mHz";
   else if (val > 1e6 * fac) val = (val / 1e6).toFixed(sigDigits) + " MHz";
   else if (val > 1e3 * fac) val = (val / 1e3).toFixed(sigDigits) + " KHz";
   else                      val = (val / 1e0).toFixed(sigDigits) + "  Hz";
   
   return val.replace(',', '.');
}

function InterpretToRandPulserThreshold(v) {
   var freq = parseNum(v);
   
   if (v.match(/khz/i)) freq *= 1e3;
   else if (v.match(/mhz/i)) freq *= 1e6;
   
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
         if (!id) {console.debug("Expandable Box without ID!"); return;}
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

function id(x) {return x;}