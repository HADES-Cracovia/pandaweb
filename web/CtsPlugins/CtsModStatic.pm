# This module defines all registers, that are statically mapped,
# i.e. have a fixed address, that does not have to be calculated
# during evaluation.
# By definition, these registers belong to the first address-block
# (stating at 0xa000).

package CtsModStatic;
@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;
use CtsBaseModule;

sub moduleName {"Base Registers"}

sub init {
   my $self = $_[0];

   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};
   
   my $trb = $self->{'_cts'}->{'_trb'};
   
   my $debug_block = 0xa000;

   $prop->{'cts_clock_frq'} = 1e8;
   $prop->{'trb_endpoint'} = $trb->getEndpoint;
   $prop->{'trb_compiletime'} = $trb->read(0x40);
   
   $regs->{'cts_cnt_trg_asserted'} = TrbRegister->new(0x00 + $debug_block, $trb, {}, {
      'accessmode' => "ro",
      'label' => "Cycles with trigger asserted",
      'monitorrate' => 1
   });
   
   $regs->{'cts_cnt_trg_edges'}    = TrbRegister->new(0x01 + $debug_block, $trb, {}, {
      'accessmode' => "ro",
      'label' => "Trigger rising edges",
      'monitorrate' => 1
   });
   
   $regs->{'cts_cnt_trg_accepted'} = TrbRegister->new(0x02 + $debug_block, $trb, {}, {
      'accessmode' => "ro",
      'label' => "Triggers accepted",
      'monitorrate' => 1
   });
   
   $regs->{'cts_cur_trg_state'}    = TrbRegister->new(0x03 + $debug_block, $trb, {
      'mask'     => {'lower' =>  0, 'len' => 16, 'type' => 'mask'}, 
      'type'     => {'lower' => 16, 'len' =>  4, 'type' => 'hex'},
      'asserted' => {'lower' => 20, 'len' =>  1, 'type' => 'bool'}
   }, {
      'accessmode' => "ro",
      'monitor' => '1',
      'label' => "Current Trigger State"
   });

   $regs->{'cts_buf_trg_state'}    = TrbRegister->new(0x04 + $debug_block, $trb, {
      'mask'     => {'lower' =>  0, 'len' => 16, 'type' => 'mask'},
      'type'     => {'lower' => 16, 'len' =>  4, 'type' => 'hex'}
   }, {
      'accessmode' => "ro",
      'monitor' => '1',
      'label' => "Buffered Trigger State"
   });
   
   $regs->{'cts_td_fsm_state'}    = TrbRegister->new(0x05 + $debug_block, $trb, {
      'state'    => {'lower' => 0,  'len' => 32, 'type' => 'enum', 'enum' => {
         0x0001 => 'TD_FSM_IDLE', 
         0x0002 => 'TD_FSM_SEND_TRIGGER',
         0x0004 => 'TD_FSM_WAIT_FEE_RECV_TRIGGER',
         0x0008 => 'TD_FSM_FEE_ENQUEUE_INPUT_COUNTER',
         0x0010 => 'TD_FSM_FEE_ENQUEUE_CHANNEL_COUNTER',
         0x0020 => 'TD_FSM_FEE_ENQUEUE_IDLE_COUNTER',
         0x0040 => 'TD_FSM_FEE_ENQUEUE_DEAD_COUNTER',
         0x0080 => 'TD_FSM_FEE_ENQUEUE_TRIGGER_ASSERTED_COUNTER',
         0x0100 => 'TD_FSM_FEE_ENQUEUE_TRIGGER_EDGES_COUNTER',
         0x0200 => 'TD_FSM_FEE_ENQUEUE_TRIGGER_ACCEPTED_COUNTER',
         0x0400 => 'TD_FSM_FEE_ENQUEUE_TIMESTAMP',
         0x0800 => 'TD_FSM_FEE_COMPLETE',
         0x1000 => 'TD_FSM_WAIT_TRIGGER_BECOME_IDLE',
         0x2000 => 'TD_FSM_DEBUG_LIMIT_REACHED'
         }}
   }, {
      'accessmode' => "ro",
      'monitor' => '1',
      'label' => "TD FSM State"
   });
   
   $regs->{'cts_ro_fsm_state'}    = TrbRegister->new(0x06 + $debug_block, $trb, {
      'state'    => {'lower' => 0,  'len' => 32, 'type' => 'enum', 'enum' => {
         0x01 => 'RO_FSM_IDLE', 
         0x02 => 'RO_FSM_SEND_REQUEST',
         0x04 => 'RO_FSM_WAIT_BECOME_BUSY',
         0x08 => 'RO_FSM_WAIT_BECOME_IDLE',
         0x10 => 'RO_FSM_DEBUG_LIMIT_REACHED'
      }}
   }, {
      'accessmode' => "ro",
      'monitor' => '1',
      'label' => "RO FSM State"
   });
   
   $regs->{'cts_ro_queue'} = TrbRegister->new(0x07 + $debug_block, $trb, {
      'count'     => {'lower' => 0,  'len' => 16},
      'state'     => {'lower' => 30, 'len' =>  2, 'type' => 'enum', 'enum' => {
         0x0 => 'Active',
         0x1 => 'Empty',
         0x2 => 'Full'
      }}
   }, {
      'accessmode' => "ro",
      'monitor' => '1',
      'label' => "RO Queue State"
   });
   
   $regs->{'cts_fsm_limits'} = TrbRegister->new(0x08 + $debug_block, $trb, {
      'td'  => {'lower' =>  0, 'len' => 16},
      'ro'  => {'lower' => 16, 'len' => 16}
   }, {
      'accessmode' => "rw",
      'label' => "FSM Blocking (debug)",
      'monitor' => 1,
      'export' => 1
   });
   
   $regs->{'cts_readout_config'} = TrbRegister->new(0x09 + $debug_block, $trb, {
      'input_cnt'     => {'lower' => 0, 'len' => 1, 'type' => 'bool'},
      'channel_cnt'   => {'lower' => 1, 'len' => 1, 'type' => 'bool'},
      'idle_dead_cnt' => {'lower' => 2, 'len' => 1, 'type' => 'bool'},
      'trg_cnt'       => {'lower' => 3, 'len' => 1, 'type' => 'bool'},
      'timestamp'     => {'lower' => 4, 'len' => 1, 'type' => 'bool'}
   }, {
      'accessmode' => "rw",
      'label' => "Readout configuration",
      'monitor' => '1',
      'export' => 1
   });
   
   $regs->{'cts_cnt_dead_time'} = TrbRegister->new(0x0a + $debug_block, $trb, {}, {
      'accessmode' => "ro",
      'label' => "Dead time counter",
      'monitor' => 1
   }); 
   
   $regs->{'cts_cnt_idle_time'} = TrbRegister->new(0x0b + $debug_block, $trb, {}, {
      'accessmode' => "ro",
      'label' => "Idle time counter",
      'monitor' => 1
   });
 
   $regs->{'cts_throttle'} = TrbRegister->new(0x0c + $debug_block, $trb, {
      'threshold'     => {'lower' =>  0, 'len' => 10},
      'enable'        => {'lower' => 10, 'len' => 1, 'type' => 'bool'},
      'stop'          => {'lower' => 31, 'len' => 1, 'type' => 'bool'}
   }, {
      'accessmode' => "rw",
      'label' => "Trigger Throttle",
      'monitor' => 1,
      'export' => 1
   });
   
   if ($prop->{'trb_compiletime'} >  1383523200) {
      eval {
         # really ugly solution, but we currently have to read the register in order
         # to verify its existing ...
         $regs->{'cts_eventbuilder'} = TrbRegister->new(0x0d + $debug_block, $trb, {
            'mask'         => {'lower' =>  0, 'len' => 16,'type' => 'mask'},
            'rr_interval'  => {'lower' => 16, 'len' => 8, 'type' => 'uint'},
            'cal_eb'       => {'lower' => 24, 'len' => 4, 'type' => 'uint'},
            'use_cal_eb'   => {'lower' => 28, 'len' => 1, 'type' => 'bool'}
         
         }, {
            'accessmode' => "rw",
            'label' => "Event Builder Selection",
            'monitor' => 1,
            'export' => 1
         });
         $regs->{'cts_eventbuilder'}->read();
         1;
      } and do {
         $prop->{'cts_eventbuilder_rr'} = 1;
      }
   }

}

1;
