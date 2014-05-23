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
    makeCookies();
   
    }
    

  function settarget(e) {
    if(document.getElementById("target"))
      command=document.getElementById("target").value;
    var opt = "";
    if(document.getElementById("rate").checked) opt += "rate";
    if(document.getElementById("cache").checked) opt += "cache";
    com = command.split('&');
    command = "";
    for(i = 0; i < com.length; i++) {
      if (com[i] != "") { 
         var part = com[i].split('-');
         command += part[0]+"-"+part[1]+"-"+part[2] + "-" + opt + "&";
         }
      }
      
    refresh(period);
    makeCookies();
  
    }
    
/*    command = "";
    for(i = 0; i < part.length; i++) {
      if (part[i] != "rate" && part[i] != "cache" && part[i] != "ratechache" && part[i] != "") {
        command += part[i] + '-';
        }
      }
    command += opt;*/    
    
  function setaddress(e) {

    address=document.getElementById("address").value;
    com = command.split('&');
    command = "";
    for(i = 0; i < com.length; i++) {
      if (com[i] != "") { 
         var part = com[i].split('-');
         command += part[0]+"-"+part[1]+"-"+part[2] + "-" + part[3] + "&";
         }
      }    
    refresh(period);
    makeCookies();
    }


  function makeCookies() {
    setCookie("rate"+currentpage,document.getElementById("rate").checked);
    setCookie("cache"+currentpage,document.getElementById("cache").checked);
    if(document.getElementById("target")) {
      setCookie("target"+currentpage,document.getElementById("target").value);
      }
    if(document.getElementById("period")) {
      setCookie("period"+currentpage,document.getElementById("period").value);
      }
    if(document.getElementById("address")) {
      setCookie("address"+currentpage,document.getElementById("address").value);
      }       
    }
 
  function eatCookies() {
    var t = getCookie("address"+currentpage);
    if (t != "" && document.getElementById("address")) {
      document.getElementById("address").value = t;
      }
    t = getCookie("period"+currentpage);
    if (t != "" && document.getElementById("period")) {
      document.getElementById("period").value = t;
      }
    t = getCookie("target"+currentpage);
    if (t != "" && document.getElementById("target")) {
      document.getElementById("target").value = t;
      }
    t = getCookie("cache"+currentpage);
    if (t != "" && document.getElementById("cache")) {
      document.getElementById("cache").checked = (t=="true")?true:false;
      }
    t = getCookie("rate"+currentpage);
    if (t != "" && document.getElementById("rate")) {
      document.getElementById("rate").checked = (t=="true")?true:false;
      }      
    setperiod();
    settarget();
    setaddress();
    }
 
/*From w3schools.com*/ 
  function getCookie(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(';');
    for(var i=0; i<ca.length; i++) {
      var c = ca[i].trim();
      if (c.indexOf(name)==0) {
        var part  = c.split('=');
        return part[1];
        }
      }
    return "";
    } 
    
/*From w3schools.com*/
  function setCookie(cname,cvalue) {
    var d = new Date();
    d.setTime(d.getTime()+(30*24*60*60*1000));
    var expires = "expires="+d.toGMTString();
    document.cookie = cname + "=" + cvalue + "; " + expires;
    } 
    
    