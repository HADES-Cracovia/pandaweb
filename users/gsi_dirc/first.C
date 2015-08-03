void first()
{

   base::ProcMgr::instance()->SetRawAnalysis(true);

   // this limits used for liner calibrations when nothing else is available
   hadaq::TdcMessage::SetFineLimits(31, 421);

   // default channel numbers and edges mask
   hadaq::TrbProcessor::SetDefaults(33, 0x2);

   hadaq::HldProcessor* hld = new hadaq::HldProcessor();

   // About time calibration - there are two possibilities
   // 1) automatic calibration after N hits in every enabled channel.
   //     Just use SetAutoCalibrations method for this
   // 2) generate calibration on base of provided data and than use it later statically for analysis
   //     Than one makes special run with SetWriteCalibrations() enabled.
   //     Later one reuse such calibrations enabling only LoadCalibrations() call

   hadaq::TrbProcessor* trb3_1 = new hadaq::TrbProcessor(0x8000, hld);
   trb3_1->SetHistFilling(4);
   trb3_1->SetCrossProcess(true);
   trb3_1->CreateTDC(0x2000, 0x2001, 0x2002, 0x20003);
   // enable automatic calibration, specify required number of hits in each channel
   //trb3_1->SetAutoCalibrations(80000);
   // calculate and write static calibration at the end of the run
   //trb3_1->SetWriteCalibrations("run1");
   trb3_1->LoadCalibrations("run1");

   hadaq::TrbProcessor* trb3_2 = new hadaq::TrbProcessor(0x800b, hld);
   trb3_2->SetHistFilling(4);
   trb3_2->SetCrossProcess(true);
   trb3_2->CreateTDC(0x202c, 0x202d, 0x202e, 0x202f);
   //trb3_2->SetAutoCalibrations(80000);
   //trb3_2->SetWriteCalibrations("run1");
   trb3_2->LoadCalibrations("run1");

   // this is array with available TDCs ids
   int tdcmap[8] = { 0x2000, 0x2001, 0x2002, 0x2003, 0x202c, 0x202d, 0x202e, 0x202f };

   // TDC subevent header id

   for (int cnt=0;cnt<8;cnt++) {

      hadaq::TdcProcessor* tdc = hld->FindTDC(tdcmap[cnt]);
      if (tdc==0) continue;

      // specify reference channel
      //tdc->SetRefChannel(0, 0, 0x202c, 20000,  9597E6., 9603E6., true);
      if(cnt==0) {
	tdc->SetRefChannel(0, 0, 0x2001, 20000,  -100., 100., true);
      }
      //tdc->SetRefChannel(3, 1, 0xffff, 20000,  -10., 10., true);
      //      continue;

      //tdc->SetRefChannel(4, 2, 0xffff, 20000,  -10., 10., true);
//      tdc->SetRefChannel(6, 4, 0xc010, 20000,  -20., 20., true);
//      tdc->SetRefChannel(7, 5, 0xc010, 20000,  -20., 20., true);
//      tdc->SetRefChannel(8, 0, 0xc010, 20000,  -90., 80., true);
//      tdc->SetRefChannel(9, 0, 0xc010, 20000,  -200., 200., true);

//      continue;


      if (cnt==1) {
         // specify reference channel from other TDC
	//tdc->SetRefChannel(0, 0, 0xc000, 20000,  -30., 30., true);
	tdc->SetRefChannel(0, 0, 0x2000, 20000,  -20., 20., true);
         //tdc->SetRefChannel(6, 6, 0xc000, 20000,  -20., 20., true);
	tdc->SetRefChannel(7, 7, 0x2000, 20000,  -20., 20., true);
      }

      if (cnt>1) continue;

      // specify reference channel

      /*
      tdc->SetRefChannel(0, 0, 0x202d, 20000,  -100., 100., true);
      tdc->SetRefChannel(1, 0, 0xffff, 20000,  -800., 800., true);
      tdc->SetRefChannel(2, 0, 0xffff, 20000,  -200., 200., true);
      tdc->SetRefChannel(3, 0, 0xffff, 20000,  -200., 200., true);
      tdc->SetRefChannel(4, 0, 0xffff, 20000,  -200., 200., true);
      */

      // for old FPGA code one should have epoch for each hit, no longer necessary
      // tdc->SetEveryEpoch(true);

      // When enabled, time of last hit will be used for reference calculations
      // tdc->SetUseLastHit(true);

   }

}



