// this is example for

#include <stdlib.h>

void first()
{
  //base::ProcMgr::instance()->SetRawAnalysis(true);
    base::ProcMgr::instance()->SetTriggeredAnalysis(true);

   // all new instances get this value
   base::ProcMgr::instance()->SetHistFilling(4);

   // this limits used for liner calibrations when nothing else is available
   hadaq::TdcMessage::SetFineLimits(31, 491);

   // default channel numbers and edges mask
   hadaq::TrbProcessor::SetDefaults(33, 2);

   // [min..max] range for TDC ids
   //hadaq::TrbProcessor::SetTDCRange(0x610, 0x613);
   hadaq::TrbProcessor::SetTDCRange(0x1130, 0x1603);

   // [min..max] range for HUB ids
   hadaq::TrbProcessor::SetHUBRange(0x8000, 0x82FF);

   // when first argument true - TRB/TDC will be created on-the-fly
   // second parameter is function name, called after elements are created
   hadaq::HldProcessor* hld = new hadaq::HldProcessor(true, "after_create");

   const char* calname = getenv("CALNAME");
   if ((calname==0) || (*calname==0)) calname = "test_";
   const char* calmode = getenv("CALMODE");
   int cnt = (calmode && *calmode) ? atoi(calmode) : 100000;
   const char* caltrig = getenv("CALTRIG");
   unsigned trig = (caltrig && *caltrig) ? atoi(caltrig) : 0x1;
   const char* uset = getenv("USETEMP");
   unsigned use_temp = 0; // 0x80000000;
   if ((uset!=0) && (*uset!=0) && (strcmp(uset,"1")==0)) use_temp = 0x80000000;

   printf("HLD configure calibration calfile:%s  cnt:%d trig:%X temp:%X\n", calname, cnt, trig, use_temp);

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
   hld->ConfigureCalibration(calname, cnt, (1 << trig) | use_temp);

   // only accept trigger type 0x1 when storing file
   // new hadaq::HldFilter(0x1);

   // create ROOT file store
   // base::ProcMgr::instance()->CreateStore("td.root");

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
      trb->SetPrintErrors(10);
   }

   unsigned firsttdc = 0;

   for (unsigned k=0;k<hld->NumberOfTDC();k++) {
      hadaq::TdcProcessor* tdc = hld->GetTDC(k);
      if (tdc==0) continue;

      if (firsttdc == 0) firsttdc = tdc->GetID();

      printf("Configure %s!\n", tdc->GetName());

      // try to build abs time difference between 0 channels
      if (tdc->GetID() != firsttdc)
         tdc->SetRefChannel(0, 0, (0x70000 | firsttdc), 6000,  -20., 20.);

      /*
      tdc->SetRefChannel(1,6, 0xffff, 6000, -20, 20); // trigger
      tdc->SetRefChannel(2,1, 0xffff, 6000, -20, 20); // TOT
      tdc->SetRefChannel(6,1, 0xffff, 6000, -20, 20);  // TOT

      tdc->SetRefChannel(5,1, 0xffff, 6000, -20, 20); // LED DIFF

      */

      //tdc->SetRefChannel(14,16, 0xffff, 6000, -20, 20); // TOT
      //tdc->SetRefChannel(16,14, 0xffff, 6000, -20, 20); // TOT

      //tdc->SetRefChannel(16,0, 0xffff, 6000, -20, 20); // TOT
      //tdc->SetRefChannel(14,0, 0xffff, 6000, -20, 20); // TOT
		  //tdc->SetRefChannel(16,14, 0xffff, 6000, -20, 20); // TOT
      
      /*
      tdc->SetRefChannel(27,32, 0xffff, 6000, -20, 20); // TOT
      tdc->SetRefChannel(28,27, 0xffff, 6000, -20, 20); // TOT
      tdc->SetRefChannel(32,28, 0xffff, 6000, -20, 20);  // TOT
      */
      //      tdc->SetRefChannel(11,1, 0xffff, 6000, -20, 20); // LED DIFF
      //tdc->SetRefChannel(2,1, 0xffff, 6000, -20, 20); // LED DIFF
      //tdc->SetRefChannel(12,2, 0xffff, 6000, -20, 20); // LED DIFF
      tdc->SetUseLastHit(false);
      
      if (tdc->GetID() == 0x1130) {
	//	tdc->SetRefChannel(31,1, 0x1130, 6000, -20, 20); // LED DIFF
	//tdc->SetRefChannel(32,2, 0x1130, 6000, -20, 20); // LED DIFF
	//tdc->SetRefChannel(1,2, 0x1130, 6000, -20, 20); // LED DIFF
	//tdc->SetRefChannel(2,31, 0x1130, 6000, -20, 20); // LED DIFF
      }

      /*
      if (tdc->GetID() == 0x1580) {
	tdc->SetRefChannel(31,1, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel(32,2, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel( 1,2, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel(2,31, 0x1580, 20000, -20, 20); // LED DIFF
      }
      */

      /*
      if (tdc->GetID() == 0x1580) {
	tdc->SetRefChannel(21,17, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel(22,18, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel(17,18, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel(18,21, 0x1580, 20000, -20, 20); // LED DIFF
      }
      */
      
      if (tdc->GetID() == 0x1580) {
	//	tdc->SetRefChannel(9,11, 0x1580, 20000, -20, 20); // LED DIFF
	//      tdc->SetRefChannel(11,9, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel(17,21, 0x1580, 20000, -20, 20); // LED DIFF
	tdc->SetRefChannel(18,17, 0x1580, 20000, -20, 20); // LED DIFF
      }


      if (tdc->GetID() == 0x1133) {
	//tdc->SetRefChannel(1,0, 0x1133, 6000, -200, -100); // LED DIFF
	tdc->SetRefChannel(1,31, 0x1130, 6000, -20, 20); // LED DIFF
	tdc->SetRefChannel(11,1, 0x1133, 6000, -20, 20); // LED DIFF
      }
	//tdc->SetRefChannel(31,27, 0xffff, 6000, -20, 20); // LED DIFF
      

      // tdc->SetRefChannel(1, 0, 0xffff, 6000,  -160., -100.);

      // if (tdc->GetID() != firsttdc)
      //   tdc->SetDoubleRefChannel(1, (firsttdc << 16) | 1,  6000,  -30., 30., 0, 0, 0);

      // tdc->SetUseLastHit(true);
      //for (unsigned nch=1;nch<tdc->NumChannels();nch++) {
    //     double shift = 0;
    //     if (nch % 2 == 0) shift = 100.;
    //     tdc->SetRefChannel(nch, 0, 0xffff, 6000,  shift, shift + 60);
     // }
   }
}


