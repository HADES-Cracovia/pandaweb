var load_trbnet_current_id = 0;
var load_trbnet_current_card = 0;
var load_trbnet_current_asic = 0;
var load_trbnet_current_reg = 0;

var data_ready = true;

function read_and_update(val, opt) {
    var o = opt[0];
    var ss = "";
    if (val.length == 7)
        ss = val.substring(5,6);
    else
        ss = val.substring(5,7);

    var cid = o[2];
    var reg = o[3];
    var v = parseInt(ss);

    switch(reg) {
        case 0:
            var peaking = v & 0x3;
            var gain = (v & 0xc) >> 2;
            document.getElementById("AMPLI_asic"+cid).selectedIndex = 3-gain;
            document.getElementById("PEAK_Pasic"+cid).selectedIndex = peaking;
            break;
        case 1:
            var tc1r = v & 0x7;
            var tc1c = (v & 0x38) >> 3;
            document.getElementById("TC1C_Pasic"+cid).selectedIndex = tc1c;
            document.getElementById("TC1R_Pasic"+cid).selectedIndex = tc1r;
            break;
        case 2:
            var tc2r = v & 0x7;
            var tc2c = (v & 0x38) >> 3;
            document.getElementById("TC2C_Pasic"+cid).selectedIndex = tc2c;
            document.getElementById("TC2R_Pasic"+cid).selectedIndex = tc2r;
            break;
        case 3:
            var vth = v & 0x3f;
            jQuery("#bar"+cid+"0").val(v*2);
            jQuery("#bar"+cid+"0").trigger("oninput");
            break;

        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
        case 11:
            var bl = v & 0x1f;
            jQuery("#bar"+cid+(reg-3).toString()).val(-31 + v*2);
            jQuery("#bar"+cid+(reg-3).toString()).trigger("oninput");
            break;
    }


    opt.shift();
    send_and_read(opt);
};

function no_data() {
    data_ready = true;
}

function preparePanels() {
    createPanel();

    jQuery("#board_panel").find(".input_cable_conn").each(function() {
            $(this).attr("checked", true);
            $(this).change();
            });

    jQuery("#board_panel").find(".asic-table").each(function() {
            $(this).attr("checked", true);
            $(this).change();
            });
}

function loadSettingsFromTrbnet() {
    preparePanels();
    prepareDataLoad();
};

function prepareDataLoad(ignoreSelection=false) {
    var registersValues = [];//array storing 12 registers values for one asic
    var cmdWordToSend = [];
    var cmdWordToSendTable_local = [];

    var queue = new Array();

    //checking selected asics
    for (var xx = 1 ; xx<= numberOfTdc; xx++) {//tdc iteration
        for (var yy=1 ; yy <= 3 ; yy++){//cable conn iteration for each tdc
            for (var zz=1; zz<=2 ; zz++ ) {//iterating through asics
                var currentId = ''+xx+yy+zz;
                if ((document.getElementById("asic_"+currentId).checked == true && document.getElementById("cable_conn_"+xx+yy).checked == true) || ignoreSelection) {
                    for (var i = 0; i < 12; ++i) {//iterating through register value list and add header
                        var binaryString = "00000000000"+convertToBinary(yy-1,2)+"1010"+convertToBinary(zz,2)+"1"+convertToBinary(i,4)+"00000000";
                        var board_addr = '0x'+tdcAddr[xx-1]
                            var str_hex = parseInt(binaryString, 2).toString(16);
                        var q = [board_addr, str_hex, currentId, i];
                        queue.push(q);
                    }
                }
            }
        }
    }

    var textarea = document.getElementById('log1');
    var d = new Date();
    var h = d.getHours();
    var m = d.getMinutes();
    var s = d.getSeconds();
    textarea.value+= "IMPORT DONE! == time: "+ h + ":" + m + ":" + s + "\n\n";
    textarea.scrollTop = textarea.scrollHeight;

    var l = queue.length;
    queue.push(l);

    $( "#js-button-open" ).trigger( "click" );

    send_and_read(queue);
    return cmdWordToSendTable_local;
}

function send_and_read(queue) {
    var l = queue.length;
    var ql = queue[l-1];

    if (l > 1)
    {
        p = queue[0];

        cmdWordToSend = p[0]+"-"+"a000-"+"0x"+p[1];

        var cb;  
        getdata("../commands/put.pl?"+cmdWordToSend, cb);
        var cmdWordToRead = p[0]+"-"+"a000";

        data_ready = false;
        getdata('../commands/get.pl?'+cmdWordToRead, read_and_update, queue);

        var currentPercent = calc_progress(ql - l + 2, ql);
        if ((ql - l + 2) == 1)
          jQuery('#progress-bar').html('Wait for finish');
        else if (currentPercent == "100")
          jQuery('#progress-bar').html('Finished');
//         jQuery('#progress-bar').html(currentPercent+'% Complete');
        jQuery('#progress-bar').css('width', currentPercent+'%').attr('aria-valuenow', currentPercent);
        jQuery('.modal-footer').html((cmdWordToSend.replace('-',' ')).replace('-',' '));
    }
    else
    {
        $('.progress').modal('hide');
    }
}
