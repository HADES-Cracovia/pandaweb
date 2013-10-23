  function editsetting(e) {
    if(e.target.getAttribute("class") && e.target.getAttribute("class").indexOf("editable")!=-1) {
      var text = e.target.getAttribute("cstr");
          text += "\nCurrent Value: "+e.target.innerHTML+" ("+e.target.getAttribute("raw")+")\n ";
      var newval = prompt(text,e.target.getAttribute("raw"));
      if (newval != null) {
        getdataprint('../xml-db/put.pl?'+e.target.getAttribute("cstr")+'-'+newval,'returntext',false,-1,refresh);
        }
      }
    }
    
  function refresh(time = 0) {
    if(time == -1) {  //call immediately and only once
      getdataprint('../xml-db/get.pl?'+command,'content',false,0);
      }
    else if (time > 0) { //call with timeout
      clearTimeout(Timeoutvar);
      Timeoutvar = setTimeout("getdataprint('../xml-db/get.pl?'+command,'content',false,"+period+",refresh)",period);
      }
    else {  //call immediately, then with timeout
      clearTimeout(Timeoutvar);
      getdataprint('../xml-db/get.pl?'+command,'content',false,period,refresh);
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
    command=document.getElementById("target").value;
    refresh(period);
    }
    
  function setaddress(e) {
    address=document.getElementById("address").value;
    var part = command.split('-');
    command=part[0]+"-"+address+"-"+part[2];
    refresh(period);
    }