  function editsetting(e) {
    if(e.target.getAttribute("class") && e.target.getAttribute("class").indexOf("editable")!=-1) {
      var curr = e.target.innerHTML.split('<',1);
      if (e.target.parentNode.getAttribute("bit") == '1') { // search for fields that represent single bits
        console.debug("single bit clicked");
        if ( parseInt(e.target.parentNode.getAttribute("raw")) == 0 )
          getdataprint('../xml-db/put.pl?'+e.target.parentNode.getAttribute("cstr")+'-'+'1','returntext',false,-1,refresh);
        if ( parseInt(e.target.parentNode.getAttribute("raw")) == 1 )
          getdataprint('../xml-db/put.pl?'+e.target.parentNode.getAttribute("cstr")+'-'+'0','returntext',false,-1,refresh);
        return;
      }
      var text = e.target.parentNode.getAttribute("cstr");
          text += "\nCurrent Value: "+curr+" ("+e.target.parentNode.getAttribute("raw")+")\n ";
      var newval = prompt(text,e.target.parentNode.getAttribute("raw"));
      if (newval != null) {
        getdataprint('../xml-db/put.pl?'+e.target.parentNode.getAttribute("cstr")+'-'+newval,'returntext',false,-1,refresh);
        }
      }
    }
    
  function refresh(time = 0) {
    if(time == -1) {  //call immediately and only once
      getdataprint(GETCOMMAND+'?'+command,'content',false,0);
      }
    else if (time > 0) { //call with timeout
      clearTimeout(Timeoutvar);
      Timeoutvar = setTimeout("getdataprint(GETCOMMAND+'?'+command,'content',false,"+period+",refresh)",period);
      }
    else {  //call immediately, then with timeout
      clearTimeout(Timeoutvar);
      getdataprint(GETCOMMAND+'?'+command,'content',false,period,refresh);
      }
    }
  
  function setperiod(e) {
    period = document.getElementById("period").value;
    if (period == -1) {
      clearTimeout(Timeoutvar);
      }
    else if (period < 100) {
      period = 1000;
      document.getElementById("period").value = period;
      refresh(period);
      }
    else {
      refresh(period);
      }
    }
    
  
  function settarget(e) {
    if(document.getElementById("target"))
      command=document.getElementById("target").value;
    var opt = "";
    if(document.getElementById("rate").checked) opt += "rate";
    if(document.getElementById("cache").checked) opt += "cache";
    var part = command.split('-');
    command = part[0]+"-"+part[1]+"-"+part[2] + "-" + opt;
    refresh(period);
    }
    
  function setaddress(e) {
    address=document.getElementById("address").value;
    var part = command.split('-');
    command=part[0]+"-"+address+"-"+part[2]+"-"+part[3];
    refresh(period);
    }
