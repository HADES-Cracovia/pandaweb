#include <stdio.h>

// #include "TTree.h"

#include "base/EventProc.h"
#include "base/Event.h"
#include "hadaq/TdcSubEvent.h"

class SecondProc : public base::EventProc {
protected:

  std::string fTdcId;      //!< tdc id where channels will be selected

  double      fHits[33][2];    //!< 33 channel, abstract hits, two dges
  //unsigned eventnumber = 0;
  
  base::H1handle  hNumHits; //!< histogram with hits number
  
  base::H1handle  hToTch3;
  base::H1handle  hToTch4;
  base::H1handle  hTdifflch3ch4;
  base::H1handle  hTdifftch3ch4;
  base::H1handle  hTdifflch3ch4_cut1;
  base::H1handle  hTdifftch3ch4_cut1;
  base::H1handle  hTdifflch3ch4_cut2;
  base::H1handle  hTdifftch3ch4_cut2;
  
public:
  SecondProc(const char* procname, const char* _tdcid) :
    base::EventProc(procname),
    fTdcId(_tdcid)

  {
    printf("Create %s for %s\n", GetName(), fTdcId.c_str());

    hNumHits = MakeH1("NumHits","Num hits", 100, 0, 100, "number");

    hToTch3 = MakeH1("hToTch3","ToTch3",400,-20,20, "ns");
    hToTch4 = MakeH1("hToTch4","ToTch4",400,-20,20, "ns");
    hTdifflch3ch4 = MakeH1("hTdifflch3ch4","Tdifflch3ch4",500,-10,20,"ns");
    hTdifftch3ch4 = MakeH1("hTdifftch3ch4","Tdifftch3ch4",500,-10,20,"ns"); 
    hTdifflch3ch4_cut1 = MakeH1("hTdifflch3ch4_cut1","Tdifflch3ch4",500,-10,20,"ns");
    hTdifftch3ch4_cut1 = MakeH1("hTdifftch3ch4_cut1","Tdifftch3ch4",500,-10,20,"ns");
    hTdifflch3ch4_cut2 = MakeH1("hTdifflch3ch4_cut2","Tdifflch3ch4",500,-10,20,"ns");
    hTdifftch3ch4_cut2 = MakeH1("hTdifftch3ch4_cut2","Tdifftch3ch4",500,-10,20,"ns");
    
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
        
    //eventnumber++;
    hadaq::TdcSubEventFloat* sub =
      dynamic_cast<hadaq::TdcSubEventFloat*> (ev->GetSubEvent(fTdcId));

    //printf("%s process sub %p %s\n", GetName(), sub, fTdcId.c_str());

    // when return false, event processing is cancelled
    if (sub==0) return true;

    double num(0);

    for (unsigned cnt=0;cnt<sub->Size();cnt++) {
      const hadaq::MessageFloat& msg = sub->msg(cnt);

      unsigned chid = msg.getCh();
      unsigned edge = msg.getEdge(); // 0 - rising, 1 - falling
      // if (chid==0) { ch0tm = ext.GetGlobalTime(); continue; }

      // time relative ch0
      double tm = msg.stamp;
            
      if (chid<33) fHits[chid][edge] = tm;

      //printf("  ch:%3d tm:%f, edge:%d\n", chid, tm, edge);
      num+=1;
    }
         
    //printf("tot(%d): %f %f\n", eventnumber, (fHits[9][0] - fHits[9][1]), (fHits[11][0] - fHits[11][1]));
    //printf("led(%d): %f %f\n", eventnumber, (fHits[9][0] - fHits[11][0]), (fHits[9][1] - fHits[11][1]));

    FillH1(hNumHits, num);

    double ToTch3, ToTch4;
    double LETch3,TETch3,LETch4,TETch4;

    LETch3=fHits[3][0];
    TETch3=fHits[3][1];
    LETch4=fHits[4][0];
    TETch4=fHits[4][1];
    
    ToTch3=TETch3-LETch3 - 18;  // subtract TDC offsets
    ToTch4=TETch4-LETch4 - 19.5;  // individual offsets for each channel !

    // Leading AND Trailing edge in both channels 3+4
    if ( fabs(LETch3) <0.00001 || fabs(LETch4) < 0.00001 )
      return true;
    if ( fabs(TETch3) <0.00001 || fabs(TETch4) < 0.00001 )
      return true;
    if ( (ToTch3>8) || (ToTch4>8) || (ToTch3<0) || (ToTch4<0))
      return true;

    // Fill ToT histograms
    FillH1(hToTch3,ToTch3);
    FillH1(hToTch4,ToTch4); 
    
    // Fill dT ch4-ch3 histograms
    double tdiff_leading=LETch4-LETch3;
    double tdiff_trailing=TETch4-TETch3;
    
    if (ToTch3>0.0 && ToTch4>0.0) {
      FillH1(hTdifflch3ch4,tdiff_leading);
      FillH1(hTdifftch3ch4,tdiff_trailing);
    }
    if (ToTch3>2.0 && ToTch3<8.0 && ToTch4>2.0 && ToTch4<8.0) {
      FillH1(hTdifflch3ch4_cut1,tdiff_leading);
      FillH1(hTdifftch3ch4_cut1,tdiff_trailing);
    }
    if (ToTch3>3.5 && ToTch3<8.0 && ToTch4>3.5 && ToTch4<8.0) {
      FillH1(hTdifflch3ch4_cut2,tdiff_leading);
      FillH1(hTdifftch3ch4_cut2,tdiff_trailing);
    }                     

    return true;
  }


};


void second()
{
  //new SecondProc("A", "TDC_1133");
  //new SecondProc("A", "TDC_1580");
  new SecondProc("A", "TDC_1208");
}
