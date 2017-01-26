#include <stdio.h>

// #include "TTree.h"

#include "base/EventProc.h"
#include "base/Event.h"
#include "hadaq/TdcSubEvent.h"

class SecondProc : public base::EventProc {
protected:
  
  std::string fTdcId;      //!< tdc id where channels will be selected
  double      fHits[33][2];    //!< 33 channel, abstract hits, two dges
  
  unsigned eventnumber;

  base::H1handle  hNumHits; //!< histogram with hits number
  base::H1handle  hDif1; //!< histogram with hits number
  base::H1handle  hDif2; //!< histogram with hits number
  base::H1handle  hDif3; //!< histogram with hits number
  base::H1handle  hDif4; //!< histogram with hits number
  base::H1handle  hDif5; //!< histogram with hits number
  base::H1handle  hDif6; //!< histogram with hits number
  base::H1handle  hDif7; //!< histogram with hits number
  base::H1handle  hTot1; //!< histogram with hits number
  base::H1handle  hTot2; //!< histogram with hits number
  base::H1handle  hTot3; //!< histogram with hits number
  base::H1handle  hTot4; //!< histogram with hits number
  base::H1handle  hTot5; //!< histogram with hits number
  base::H1handle  hTot6; //!< histogram with hits number
  base::H2handle  hUser; //!< user-defined 2D histogram

public:
  SecondProc(const char* procname, const char* _tdcid) :
    base::EventProc(procname),
    fTdcId(_tdcid),
    hUser(0)
  {
    printf("Create %s for %s\n", GetName(), fTdcId.c_str());

    hNumHits = MakeH1("NumHits","Num hits", 100, 0, 100, "number");

    eventnumber = 0;

    /*
      hDif1 = MakeH1("ToT1","ToT of channel 17 (18)", 1000, 0.5, 3.0, "ns");
      hDif2 = MakeH1("LED_diff1","LED diff channel 17 - 21", 1000, -2., -1., "ns");
      hUser = MakeH2("ToT_vs_LED","ToT versus LED difference", 500, -4, 0, 500, -2, -1, "ToT/ns;LED diff/ns");
    */

    hDif1 = MakeH1("LE1","2 vs. 4", 1800, -90, 90, "ns");
    hDif2 = MakeH1("LE2","4 vs. 6", 1800, -90, 90, "ns");
    hDif3 = MakeH1("LE3","6 vs. 2", 1800, -90, 90, "ns");
    hDif4 = MakeH1("LETR1","2 vs. 4 trip", 1800, -90, 90, "ns");
    hDif5 = MakeH1("LETR2","4 vs. 6 trip", 1800, -90, 90, "ns");
    hDif6 = MakeH1("LETR3","6 vs. 2 trip", 1800, -90, 90, "ns");

    hDif7 = MakeH1("LE4", "Mean vs. middle (chan.2)", 1800, -90, 90, "ns");

    hTot1 = MakeH1("ToT1","ToT 2", 1800, -90, 90, "ns");
    hTot2 = MakeH1("ToT2","ToT 4", 1800, -90, 90, "ns");
    hTot3 = MakeH1("ToT3","ToT 6", 1800, -90, 90, "ns");

    hTot4 = MakeH1("ToT4","ToT 2, all 3", 1800, -90, 90, "ns");
    hTot5 = MakeH1("ToT5","ToT 4, all 3", 1800, -90, 90, "ns");
    hTot6 = MakeH1("ToT6","ToT 6, all 3", 1800, -90, 90, "ns");


    /*
      hDif1 = MakeH1("ToT1","ToT of channel 9", 1000, 32, 40, "ns");
      hDif2 = MakeH1("LED_diff1","LED diff channel 9 - 11", 1000, -3, -1, "ns");
      hUser = MakeH2("ToT_vs_LED","ToT versus LED difference", 500, 32, 40, 500, -4, -0, "ToT/ns;LED diff/ns");
    */

    // enable storing already in constructor
    // SetStoreEnabled();
  }

  virtual void CreateBranch(TTree* t)
  {
    // only called when tree is created in first.C
    // one can ignore
    // t->Branch(GetName(), fHits, "hits[8]/D");
  }

  virtual bool Process(base::Event* ev)
  {
    for (unsigned n=0;n<33;n++) {
      fHits[n][0] = 0.;
      fHits[n][1] = 0.;
    }

    eventnumber++;
    hadaq::TdcSubEventFloat* sub =
      dynamic_cast<hadaq::TdcSubEventFloat*> (ev->GetSubEvent(fTdcId));

    //printf("%s process sub %p %s\n", GetName(), sub, fTdcId.c_str());

    // when return false, event processing is cancelled
    if (sub==0) return true;

    hadaq::HldProcessor* hld = dynamic_cast<hadaq::HldProcessor*> (base::ProcMgr::instance()->FindProc("HLD"));
    hadaq::TrbProcessor* trb = hld ? hld->FindTRB(0x8000) : 0;
    // hadaq::TdcProcessor* tdc = hld ? hld->FindTDC(0x1340) : 0;
    //if (hld) printf("HLD event header %u\n", hld->GetLastEventHdr().GetSeqNr());
    //if (trb) printf("TRB subevent header trig:%x decoding:%x\n", trb->GetLastSubeventHdr().GetTrigNr(), trb->GetLastSubeventHdr().GetDecoding());
    // if (tdc) printf("TDC header/trailer messages raw %x %x\n", tdc->GetLastTdcHeader().getData(), tdc->GetLastTdcTrailer().getData());

    //if ()

    double num(0);

    for (unsigned cnt=0;cnt<sub->Size();cnt++) {
      const hadaq::MessageFloat& msg = sub->msg(cnt);

      unsigned chid = msg.getCh();
      unsigned edge = msg.getEdge(); // 0 - rising, 1 - falling
      // if (chid==0) { ch0tm = ext.GetGlobalTime(); continue; }

      // time relative ch0
      double tm = msg.stamp;

      // use only first hit in each channel
      if ((chid<33) && (fHits[chid][edge]==0.)) fHits[chid][edge] = tm;

      //printf("  ch:%3d tm:%f, edge:%d\n", chid, tm, edge);
      num+=1;
    }

    //printf("tot(%d): %f %f\n", eventnumber, (fHits[9][0] - fHits[9][1]), (fHits[11][0] - fHits[11][1]));
    //printf("led(%d): %f %f\n", eventnumber, (fHits[9][0] - fHits[11][0]), (fHits[9][1] - fHits[11][1]));

    FillH1(hNumHits, num);

    /*
      FillH1(hDif1, (fHits[9][1] - fHits[9][0]) );
      FillH1(hDif2, (fHits[9][0] - fHits[11][0]) );
      FillH2(hUser, (fHits[9][1] - fHits[9][0]) , (fHits[9][0] - fHits[11][0]) );
    */

    //printf("tot: %f\n", (fHits[6][1] - fHits[6][0]));
    double tot2;
    double tot4;
    double tot6;

    tot2 = fHits[2][1]  - fHits[2][0];
    tot4 = fHits[4][1]  - fHits[4][0];    
    tot6 = fHits[6][1]  - fHits[6][0];    

    
    if (tot2 > 2 && tot2 < 20) 
      FillH1(hTot1, tot2);

    if (tot4 > 1 && tot4 < 18) 
      FillH1(hTot2, tot4);

    if (tot6 > 35 && tot6 < 55) 
      FillH1(hTot3, tot6);
    

    if( fHits[6][0]!=0 && fHits[2][0]!=0 && fHits[4][0]!=0) {
      FillH1(hTot4, tot2);
      FillH1(hTot5, tot4);
      FillH1(hTot6, tot6);
    }
    

    
    if (fHits[4][0]!=0 && fHits[2][0]!=0  )
      FillH1(hDif1, (fHits[4][0]  - fHits[2][0]));
    
    if (fHits[6][0]!=0 && fHits[4][0]!=0  )
      FillH1(hDif2, (fHits[6][0]  - fHits[4][0]));

    if (fHits[6][0]!=0 && fHits[2][0]!=0 )
      FillH1(hDif3, (fHits[6][0]  - fHits[2][0]));

    if (fHits[4][0]!=0 && fHits[2][0]!=0 && fHits[6][0]!=0 )
      FillH1(hDif4, (fHits[4][0]  - fHits[2][0]));
    
    if (fHits[6][0]!=0 && fHits[4][0]!=0 && fHits[2][0]!=0 )
      FillH1(hDif5, (fHits[6][0]  - fHits[4][0]));

    if (fHits[6][0]!=0 && fHits[2][0]!=0 && fHits[4][0]!=0)
      FillH1(hDif6, (fHits[6][0]  - fHits[2][0]));

   
    if (fHits[6][0]!=0 && fHits[2][0]!=0 && fHits[4][0]!=0 &&


        tot2 > 8.0 && tot2 < 10.0 &&
	tot4 > 8 && tot4 < 14 &&
	tot6 > 45.0 && tot6 < 51.0 

        /*
        tot2 > 7. && tot2 < 12. &&
	tot4 > 8. && tot4 < 13.0 &&
	tot6 > 46.0 && tot6 < 50.0 
        */

        
        

	)
      FillH1(hDif7, (fHits[6][0]  + fHits[4][0])/2 - fHits[2][0]  );


    

    // cuts no longer needed - one see only normal triggers here
    /*	 if(
	 ((fHits[6][1] - fHits[6][0]) > 38)  && ((fHits[6][1] - fHits[6][0])<48) &&
	 ((fHits[4][1] - fHits[4][0]) > 35)  && ((fHits[4][1] - fHits[4][0])<42) &&
	 ((fHits[2][1] - fHits[2][0]) > 35)  && ((fHits[2][1] - fHits[2][0])<42)
	 ) {
	 //FillH1(hDif1, (fHits[6][0] + fHits[4][0])/2 - fHits[2][0] );
	 FillH1(hDif1, (fHits[6][0]  - fHits[2][0] ));
	 //FillH1(hDif2, (fHits[1][1] - fHits[2][1]) );
	 }
    */


    return true;
  }
};


void second()
{
  //new SecondProc("A", "TDC_1133");
  //new SecondProc("A", "TDC_1580");
  new SecondProc("A", "TDC_0840");
}
