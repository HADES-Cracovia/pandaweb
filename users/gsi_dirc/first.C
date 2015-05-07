void first()
{
   // analysis will work as triggerred -
   // after each event all data should be processed and flushed
   base::ProcMgr::instance()->SetTriggeredAnalysis();

   hadaq::TdcMessage::SetFineLimits(31, 421);

   hadaq::HldProcessor* hld = new hadaq::HldProcessor();

   // Following levels of histograms filling are supported
   //  0 - none
   //  1 - only basic statistic from TRB
   //  2 - generic statistic over TDC channels
   //  3 - basic per-channel histograms with IDs
   //  4 - per-channel histograms with references
   // trb3->SetHistFilling(4);

   // Load calibrations for ALL TDCs
   /// trb3->LoadCalibrations("/data.local1/padiwa/new_");

   // calculate and write calibrations at the end of the run
   //trb3->SetWriteCalibrations("/data.local1/padiwa/new_");

   // enable automatic calibrations of the channels
   //trb3->SetAutoCalibrations(100000);


   hadaq::TrbProcessor* trb3 = new hadaq::TrbProcessor(0x8000, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0010, 0x0011, 0x0012, 0x0013);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8001, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0110, 0x0111, 0x0112, 0x0113);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8002, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0210, 0x0211, 0x0212, 0x0213);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8003, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0310, 0x0311, 0x0312, 0x0313);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8004, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0410, 0x0411, 0x0412, 0x0413);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8005, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0510, 0x0511, 0x0512, 0x0513);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8006, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0610, 0x0611, 0x0612, 0x0613);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8007, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0710, 0x0711, 0x0712, 0x0713);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8008, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0810, 0x0811, 0x0812, 0x0813);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8009, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x0910, 0x0911, 0x0912, 0x0913);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8010, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1010, 0x1011, 0x1012, 0x1013);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8011, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1110, 0x1111, 0x1112, 0x1113);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8012, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1210, 0x1211, 0x1212, 0x1213);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8013, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1310, 0x1311, 0x1312, 0x1313);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8014, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1410, 0x1411, 0x1412, 0x1413);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8015, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1510, 0x1511, 0x1512, 0x1513);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8016, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1610, 0x1611, 0x1612, 0x1613);
   // trb3->SetWriteCalibrations("calibr_");
   //trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8017, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1710, 0x1711, 0x1712, 0x1713);
   // trb3->SetWriteCalibrations("calibr_");
   //trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8018, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1810, 0x1811, 0x1812, 0x1813);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8019, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x1910, 0x1911, 0x1912, 0x1913);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8020, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x2010, 0x2011, 0x2012, 0x2013);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   trb3 = new hadaq::TrbProcessor(0x8021, hld);
   trb3->SetHistFilling(2);
   trb3->CreateTDC(0x2110, 0x2111, 0x2112, 0x2113);
   // trb3->SetWriteCalibrations("calibr_");
   // trb3->LoadCalibrations("calibr_");

   // indicate if raw data should be printed
   hld->SetPrintRawData(false);


   // method set window for all TRBs/TDCs
   // hld->SetTriggerWindow(-4e-7, -0.2e-7);

   // uncomment these line to enable store of all TDC data in the tree
   // hld->SetStoreEnabled(true);

   // create store - typically done in second.C, should be called only once
   // base::ProcMgr::instance()->CreateStore("file.root");

}
