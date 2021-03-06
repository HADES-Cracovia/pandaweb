// this is example for


void first()
{
   //base::ProcMgr::instance()->SetRawAnalysis(true);
   base::ProcMgr::instance()->SetTriggeredAnalysis(true);

   // all new instances get this value
   base::ProcMgr::instance()->SetHistFilling(4);

   // configure bubbles
   //hadaq::TdcProcessor::SetBubbleMode(0, 18);

   // hadaq::TdcProcessor::SetDefaults(1024);
   hadaq::TdcProcessor::SetTriggerDWindow(-10,80);

   // this limits used for liner calibrations when nothing else is available
   hadaq::TdcMessage::SetFineLimits(31, 491);

   // default channel numbers and edges mask
   hadaq::TrbProcessor::SetDefaults(33, 3);

   // [min..max] range for TDC ids
   hadaq::TrbProcessor::SetTDCRange(0xf3d0, 0xf3da);

   // [min..max] range for HUB ids
   hadaq::TrbProcessor::SetHUBRange(0xf3db, 0xf3df);

   // when first argument true - TRB/TDC will be created on-the-fly
   // second parameter is function name, called after elements are created
   hadaq::HldProcessor* hld = new hadaq::HldProcessor(true, "after_create");

   const char* calname = getenv("CALNAME");
   if ((calname==0) || (*calname==0)) calname = "test_";
   const char* calmode = getenv("CALMODE");
   int cnt = (calmode && *calmode) ? atoi(calmode) : 100000;
   //cnt=50000;
   const char* caltrig = getenv("CALTRIG");
   unsigned trig = (caltrig && *caltrig) ? atoi(caltrig) : 0x1;
   const char* uset = getenv("USETEMP");
   unsigned use_temp = 0; // 0x80000000;
   if ((uset!=0) && (*uset!=0) && (strcmp(uset,"1")==0)) use_temp = 0x80000000;

   printf("TDC CALIBRATION MODE %d\n", cnt);

   //printf("HLD configure calibration calfile:%s  cnt:%d trig:%X temp:%X\n", calname, cnt, trig, use_temp);

   // first parameter if filename  prefix for calibration files
   //     and calibration mode (empty string - no file I/O)
   // second parameter is hits count for autocalibration
   //     0 - only load calibration
   //    -1 - accumulate data and store calibrations only at the end
   //    >0 - automatic calibration after N hits in each active channel
   // third parameter is trigger type mask used for calibration
   //   (1 << 0xD) - special 0XD trigger with internal pulser, used also for TOT calibration
   //    0x3FFF - all kinds of trigger types will be used for calibration (excluding 0xE and 0xF)
   //   0x80000000 in mask enables usage of temperature correction
   hld->ConfigureCalibration(calname, cnt, (1 << trig) | use_temp | 0x3FFF);

   // only accept trigger type 0x1 when storing file
   // new hadaq::HldFilter(0x1);

   // create ROOT file store
   //base::ProcMgr::instance()->CreateStore("td.root");

   // 0 - disable store
   // 1 - std::vector<hadaq::TdcMessageExt> - includes original TDC message
   // 2 - std::vector<hadaq::MessageFloat>  - compact form, without channel 0, stamp as float (relative to ch0)
   // 3 - std::vector<hadaq::MessageDouble> - compact form, with channel 0, absolute time stamp as double
   base::ProcMgr::instance()->SetStoreKind(2);


   // when configured as output in DABC, one specifies:
   // <OutputPort name="Output2" url="stream://file.root?maxsize=5000&kind=3"/>


}

// extern "C" required by DABC to find function from compiled code

extern "C" void after_create(hadaq::HldProcessor* hld)
{
   printf("Called after all sub-components are created\n");

   if (hld==0) return;

   for (unsigned k=0;k<hld->NumberOfTRB();k++) {
      hadaq::TrbProcessor* trb = hld->GetTRB(k);
      if (trb==0) continue;
      printf("Configure %s!\n", trb->GetName());
      trb->SetPrintErrors(100);
   }

   for (unsigned k=0;k<hld->NumberOfTDC();k++) {
      hadaq::TdcProcessor* tdc = hld->GetTDC(k);
      if (tdc==0) continue;

      printf("Configure %s!\n", tdc->GetName());

      // tdc->SetUseLastHit(true);

      // tdc->SetStoreEnabled();
      for (unsigned nch=2;nch<tdc->NumChannels();nch++)
        tdc->SetRefChannel(nch, nch-1, 0xffff, 20000,  -100., 100.);

      //tdc->SetRefChannel(6, 3, 0xffff, 20000,  -100., 100.);

      //tdc->SetRefChannel(1, tdc->NumChannels() -1 , 0xffff, 20000,  -100., 100.);

      
   }
}


