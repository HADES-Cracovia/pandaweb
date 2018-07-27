function progress() {
    var html;
    html = '<div class="progress">';
    html += '<div id="progress-bar-1" class="progress-bar progress-bar-success" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width:0%">';
    html += '0% Complete (success)';
    html += '</div>';
    html += '</div>';
    return html;
}


var cmdWordToSendTable = [];
var dataReadyFlag = 0;
var i_send = 0;

function prepareData(ignoreSelection) {
    var registersValues = [];//array storing 12 registers values for one asic
    var cmdWordToSend = [];
    var cmdWordToSendTable_local = [];
    //checking selected asics
    for (var xx = 1 ; xx<= numberOfTdc; xx++) { //tdc iteration
        for(var yy=1 ; yy <= 3 ; yy++) { //cable conn iteration for each tdc
            for (var zz=1; zz<=2 ; zz++ ) { //iterating through asics
                var currentId = ''+xx+yy+zz;
                if((document.getElementById("asic_"+currentId).checked == true && document.getElementById("cable_conn_"+xx+yy).checked == true) || ignoreSelection){
                    registersValues = fabricCmdWord(currentId);
                    for (var i =0; i < registersValues.length; i++) {//iterating through register value list and add header
                        var binaryString = "00000000000"+convertToBinary(yy-1,2)+"1010"+convertToBinary(zz,2)+"0"+convertToBinary(i,4)+registersValues[i];
                        var board_addr = "0x"+ tdcAddr[xx-1];

                        // registersValues[i] ="0x"+parseInt(binaryString,2).toString(16);
                        cmdWordToSend[i] = board_addr+"-"+"0xa000-"+"0x"+parseInt(binaryString,2).toString(16);//registersValues[i];
                        cmdWordToSendTable_local.push(cmdWordToSend[i]);
                        //var cb;
                        //getdata("./../commands/put.pl?"+cmdWordToSend[i],cb);
                        document.getElementById('log1').value+=  (cmdWordToSend[i].replace('-',' ')).replace('-',' ');
                        document.getElementById('log1').value+='\n';
                    }
                }
            }
        }
    }
    console.log('data parsed');
    //getting current hour and time so we now that settings were send and at what hour.
    var textarea = document.getElementById('log1');
    var d = new Date();
    var h = d.getHours();
    var m = d.getMinutes();
    var s = d.getSeconds();
    textarea.value+= "DONE!=========time: "+ h + ":" + m + ":" + s + "\n\n";
    textarea.scrollTop = textarea.scrollHeight;
    return cmdWordToSendTable_local;
}

function send_cb() {
    send();
}

function send() {
    if (dataReadyFlag == 0) {
        cmdWordToSendTable = prepareData(false);
        dataReadyFlag = 1;
        //creating progress bar
        $( "#js-button-open" ).trigger( "click" );
        jQuery('.modal-body').html(progress());
    }

    if( i_send < cmdWordToSendTable.length){
        getdata("./../commands/put.pl?"+cmdWordToSendTable[i_send],send_cb);

        var currentPercent = Number(((100 / cmdWordToSendTable.length)  * (i_send+1)).toFixed(1));
            jQuery('#progress-bar-1').css('width', currentPercent + "%");
            jQuery('#progress-bar-1').html(currentPercent+'% Complete (success)');
        jQuery('.modal-footer').html(  (cmdWordToSendTable[i_send].replace('-',' ')).replace('-',' '));
        i_send++;

    }
}

function preSend() {
    i_send = 0;
    dataReadyFlag =0;
    cmdWordToSendTable = [];
    send();
}

function fabricCmdWord(currentId) {
    var binaryString= [];//for each asic 12 registers have to be set. Each position in the array
    //corresponds to one register.

    //here we create 8 bit data to be write in registers
    binaryString[0]="000"+"1"+converter(document.getElementById("AMPLI_asic"+currentId).selectedIndex,2)+converter(document.getElementById("PEAK_Pasic"+currentId).selectedIndex,2);
    binaryString[1]="00"+converter(document.getElementById("TC1C_Pasic"+currentId).selectedIndex,3)+converter(document.getElementById("TC1R_Pasic"+currentId).selectedIndex,3);
    binaryString[2]="00"+converter(document.getElementById("TC2C_Pasic"+currentId).selectedIndex,3)+converter(document.getElementById("TC2R_Pasic"+currentId).selectedIndex,3);

    var tmp = document.getElementById("bar"+currentId+"0value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";} //alert("was &nbsp is "+tmp);}
    binaryString[3]="0"+ divConvertToBinary(tmp,7); //threshold is stored on 7 bits

    tmp = document.getElementById("bar"+currentId+"1value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    binaryString[4]="000"+ divConvertToBinary(Number(tmp)+31,5);

    tmp = document.getElementById("bar"+currentId+"2value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    binaryString[5]="000"+ divConvertToBinary(Number(tmp)+31,5);

    tmp = document.getElementById("bar"+currentId+"3value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    //binaryString[6]="000"+ divConvertToBinary(tmp,5);
    binaryString[6]="000"+ divConvertToBinary(Number(tmp)+31,5);

    tmp = document.getElementById("bar"+currentId+"4value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    //binaryString[7]="000"+ divConvertToBinary(tmp,5);
    binaryString[7]="000"+ divConvertToBinary(Number(tmp)+31,5);

    tmp = document.getElementById("bar"+currentId+"5value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    //binaryString[8]="000"+ divConvertToBinary(tmp,5);
    binaryString[8]="000"+ divConvertToBinary(Number(tmp)+31,5);

    tmp = document.getElementById("bar"+currentId+"6value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    //binaryString[9]="000"+ divConvertToBinary(tmp,5);
    binaryString[9]="000"+ divConvertToBinary(Number(tmp)+31,5);

    tmp = document.getElementById("bar"+currentId+"7value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    //binaryString[10]="000"+ divConvertToBinary(tmp,5);
    binaryString[10]="000"+ divConvertToBinary(Number(tmp)+31,5);

    tmp = document.getElementById("bar"+currentId+"8value").innerHTML;
    if (tmp == "&nbsp;") {tmp = "0";}
    //binaryString[11]="000"+ divConvertToBinary(tmp,5);
    binaryString[11]="000"+ divConvertToBinary(Number(tmp)+31,5);

    return binaryString;
    }

function converter(index, word_length){
    var binaryString = "";
    if (word_length==3){
        switch(index) {
            case 0:
                binaryString+="111";
                break;
            case 1:
                binaryString+="110";
                break;
            case 2:
                binaryString+="101";
                break;
            case 3:
                binaryString+="100";
                break;
            case 4:
                binaryString+="011";
                break;
            case 5:
                binaryString+="010";
                break;
            case 6:
                binaryString+="001";
                break;
            case 7:
                binaryString+="000";
                break;
        }
    }
    else
    {
        switch (index) {
            case 0:
                binaryString+="11";
                break;
            case 1:
                binaryString+="10";
                break;
            case 2:
                binaryString+="01";
                break;
            case 3:
                binaryString+="00";
                break;
        }
    }
    return binaryString;
}

//this function divides number by 2 and converts its decimal value saved in string 
// returns its binary form stored in bits which qty. is indicated by bitNum
function divConvertToBinary(n, bitNum) {
    var binaryString;
    //var n = Number(inputString);
    n = Math.floor(n/2); //we divide because threshold level has step 2mV
    binaryString = n.toString(2);
    if(binaryString.length<bitNum){
        var upperLimit = (bitNum-binaryString.length);
        for (var j=0; j<upperLimit; j++) {
            binaryString = "0" + binaryString;
        }
    }
    return binaryString;
}

function convertToBinary(input, bitNum) {
    var binaryString;

    binaryString = input.toString(2);
    if(binaryString.length<bitNum){
        var upperLimit = (bitNum-binaryString.length);
        for (var j=0; j<upperLimit; j++) {
            binaryString = "0" + binaryString;
        }
    } 
    return binaryString;
}

function resetAsic() {
    var cmdWordToSend = "";
    for (var xx = 1 ; xx<= numberOfTdc; xx++) { //tdc iteration
        for(var yy=1 ; yy <= 4 ; yy++){ //cable conn iteration for each tdc
            var currentId = ''+xx+yy;
            // if(document.getElementById("asic_"+currentId+"1").checked == true || document.getElementById("asic_"+currentId+"2").checked == true){//we check whether asic 1 or 2 check box is selected
            if((document.getElementById("asic_"+currentId+"1").checked == true  || document.getElementById("asic_"+currentId+"2").checked == true) && document.getElementById("cable_conn_"+xx+yy).checked == true ){
                var binaryString = "00000000001"+convertToBinary(yy-1,2)+"0000"+"00"+"0"+"0000"+"00000000";
                var board_addr = "0x"+ tdcAddr[xx-1];
                cmdWordToSend = board_addr+"-"+"0xa000-"+"0x"+parseInt(binaryString,2).toString(16);
                var cb; //call back - not used yet
                getdata("./../commands/put.pl?"+cmdWordToSend,cb);
            }
        }
    }
}
