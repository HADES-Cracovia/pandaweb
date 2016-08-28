#include <stdio.h>

// #include "TTree.h"

#include "base/EventProc.h"
#include "base/Event.h"
#include "hadaq/TdcSubEvent.h"

class SecondProc : public base::EventProc {
   protected:

      std::string fTdcId;      //!< tdc id where channels will be selected

      double      fHits[33][2];    //!< 33 channel, abstract hits, two dges

      base::H1handle  hNumHits; //!< histogram with hits number
      base::H1handle  hDif1; //!< histogram with hits number
      base::H1handle  hDif2; //!< histogram with hits number
      base::H2handle  hUser; //!< user-defined 2D histogram

   public:
      SecondProc(const char* procname, const char* _tdcid) :
         base::EventProc(procname),
         fTdcId(_tdcid),
         hUser(0)
      {
         printf("Create %s for %s\n", GetName(), fTdcId.c_str());

         hNumHits = MakeH1("NumHits","Num hits", 100, 0, 100, "number");

	 /*
         hDif1 = MakeH1("ToT1","ToT of channel 17 (18)", 1000, 0.5, 3.0, "ns");
         hDif2 = MakeH1("LED_diff1","LED diff channel 17 - 21", 1000, -2., -1., "ns");
         hUser = MakeH2("ToT_vs_LED","ToT versus LED difference", 500, -4, 0, 500, -2, -1, "ToT/ns;LED diff/ns");
	 */
	 
         hDif1 = MakeH1("LE1","1 vs. 2", 30000, -90, 90, "ns");
         hDif2 = MakeH1("TE2","1 vs. 2", 30000, -90, 90, "ns");
	 

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

  unsigned eventnumber = 0;
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

	 /*
         FillH1(hDif1, (fHits[9][1] - fHits[9][0]) );
         FillH1(hDif2, (fHits[9][0] - fHits[11][0]) );
         FillH2(hUser, (fHits[9][1] - fHits[9][0]) , (fHits[9][0] - fHits[11][0]) );
	 */

	 
	 FillH1(hDif1, (fHits[1][0] - fHits[2][0]) );
         FillH1(hDif2, (fHits[1][1] - fHits[2][1]) );
	 
	 

         return true;
      }
};


void second()
{
  //new SecondProc("A", "TDC_1133");
  //new SecondProc("A", "TDC_1580");
  new SecondProc("A", "TDC_1202");
}
