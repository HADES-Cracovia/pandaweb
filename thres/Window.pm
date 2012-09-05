package Window;

use strict;
use warnings;
use Data::Dumper;

my $endpoint = 0x201;

use HADES::TrbNet;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );


use QtCore4::signals
    valueChanged => ['int'];
use QtCore4::slots
    setValue => ['int'],
    setValueFine => ['int'],
    setMinimum => ['int'],
    setMaximum => ['int'];


sub horizontalSliders() {
    return this->{horizontalSliders};
}

sub verticalSliders() {
    return this->{verticalSliders};
}

sub stackedWidget() {
    return this->{stackedWidget};
}

sub controlsGroup() {
    return this->{controlsGroup};
}

sub slidersGroup() {
    return this->{slidersGroup};
}

sub minimumLabel() {
    return this->{minimumLabel};
}

sub maximumLabel() {
    return this->{maximumLabel};
}

sub valueLabel() {
    return this->{valueLabel};
}

sub valueFineLabel() {
    return this->{valueFineLabel};
}


sub minimumSpinBox() {
    return this->{minimumSpinBox};
}

sub maximumSpinBox() {
    return this->{maximumSpinBox};
}

sub valueSpinBox() {
    return this->{valueSpinBox};
}

sub valueFineSpinBox() {
    return this->{valueFineSpinBox};
}



sub slider() {
    return this->{slider};
}

sub scrollBar() {
    return this->{scrollBar};
}


my $rough_value=0;
my $fine_value=0;
#my $mode = $main::mode;
my $mode = "padiwa";


sub NEW {
    my ( $class, $parent) = @_;
    $class->SUPER::NEW( $parent );
    
    #print Dumper $rh_mode;

    trb_init_ports() or die trb_strerror();

    my $orientation = Qt::Horizontal();

    my $slider = this->{slider} = Qt::Slider($orientation);
    $slider->setFocusPolicy(Qt::StrongFocus());
    $slider->setTickPosition(Qt::Slider::TicksBothSides());
    $slider->setTickInterval(500);
    $slider->setSingleStep(1);

    my $scrollBar = this->{scrollBar} =  Qt::ScrollBar($orientation);
    $scrollBar->setFocusPolicy(Qt::StrongFocus());

#    this->{stackedWidget} = Qt::StaackedWidget();
#    this->stackedWidget->addWidget($slider);
#    this->stackedWidget->addWidget($scrollBar);


    my $direction;
    if ($orientation == Qt::Horizontal()) {
      $direction = Qt::BoxLayout::TopToBottom();
    }
    else {
      $direction = Qt::BoxLayout::LeftToRight();
    }

    my $slidersLayout = Qt::BoxLayout($direction);
    $slidersLayout->addWidget($slider);
    $slidersLayout->addWidget($scrollBar);
    this->setLayout($slidersLayout);

    this->{slidersGroup} = Qt::GroupBox("Thresholds");

    this->slidersGroup->setLayout($slidersLayout);


    this->slider->setMinimum(0x0);
    this->slider->setMaximum(0xffff);

    this->scrollBar->setMinimum(0x0);
    this->scrollBar->setMaximum(0xff);


    this->createControls(this->tr('Controls'));

    this->connect($slider, SIGNAL 'valueChanged(int)',
		  this->valueSpinBox, SLOT 'setValue(int)');

    this->connect($scrollBar, SIGNAL 'valueChanged(int)',
		  this->valueFineSpinBox, SLOT 'setValue(int)');

#    this->connect($slider, SIGNAL 'valueChanged(int)',
#		  this, SLOT 'setValue(int)');

#    this->connect($scrollBar, SIGNAL 'valueChanged(int)',
#		  this, SLOT 'setValueFine(int)');


    my $layout = Qt::HBoxLayout();
    $layout->addWidget(this->controlsGroup);
    $layout->addWidget(this->slidersGroup);

    this->setLayout($layout);

    this->valueSpinBox->setValue(3150);

    this->setWindowTitle(this->tr('Thresholds'));
}


sub setValue {
    my ($value) = @_;

    this->slider->setValue($value);
    $rough_value = $value;
    write_to_hardware();

    print "set value called: $value\n";
}

sub setValueFine {
    my ($value) = @_;
    this->scrollBar->setValue($value);
    $fine_value = $value;
    write_to_hardware();
    print "set fine value called: $value\n";
}


sub write_to_hardware {
  my $sum = $rough_value + $fine_value;

  if ($mode eq "cbm") {

      if($sum > 4095) {
	  $sum=4095;
      }
      printf "writing.... thr-value: 0x%x\n", $sum;

      foreach my $dacch (0..7) {
	  my $rh_res;
	  my $command;
	  $command= 0x00300000+($dacch<<16) + ($sum<<4);

	  $rh_res = trb_register_write($endpoint,0xd400, $command);
	  
	  if(!defined $rh_res) {
	      my $res = trb_strerror();
	      print "error output: $res\n";
	      exit();
	  }
	  $rh_res = trb_register_write($endpoint,0xd411, 0x1);
      }
  }


  if ($mode eq "padiwa") {
      if($sum > 0xffff) {
	  $sum=0xffff;
      }
      
      my $rh_res;
      $rh_res = trb_register_write($endpoint,0xd410, 0x1);
      foreach my $dacch (0..15) {

	  my $command;
	  $command= 0x00800000 + ($dacch<<16) + ($sum);

	  $rh_res = trb_register_write($endpoint,0xd400, $command);
	  
	  if(!defined $rh_res) {
	      my $res = trb_strerror();
	      print "error output: $res\n";
	      exit();
	  }
	  $rh_res = trb_register_write($endpoint,0xd411, 0x1);
      }
	  
  }
  
}


sub createControls {

    my ($title) = @_;
    this->{controlsGroup} = Qt::GroupBox($title);

    this->{valueLabel} = Qt::Label(this->tr('Current value:'));
    this->{valueFineLabel} = Qt::Label(this->tr('Current fine:'));


#    this->{minimumSpinBox} = Qt::SpinBox();
#    this->minimumSpinBox->setRange(0, 0xfff);
#    this->minimumSpinBox->setSingleStep(1);

    this->{valueSpinBox} = Qt::SpinBox();
    this->valueSpinBox->setRange(0, 0xffff);
    this->valueSpinBox->setSingleStep(10);

    this->{valueFineSpinBox} = Qt::SpinBox();
    this->valueFineSpinBox->setRange(0, 0xff);
    this->valueFineSpinBox->setSingleStep(1);


    this->connect(this->valueSpinBox, SIGNAL 'valueChanged(int)',
            this, SLOT 'setValue(int)');

    this->connect(this->valueFineSpinBox, SIGNAL 'valueChanged(int)',
            this, SLOT 'setValueFine(int)');



    my $controlsLayout = Qt::GridLayout();
#    $controlsLayout->addWidget(this->minimumLabel, 0, 0);
#    $controlsLayout->addWidget(this->maximumLabel, 1, 0);
    $controlsLayout->addWidget(this->valueLabel, 2, 0);
    $controlsLayout->addWidget(this->valueFineLabel, 3, 0);
#    $controlsLayout->addWidget(this->minimumSpinBox, 0, 1);
#    $controlsLayout->addWidget(this->maximumSpinBox, 1, 1);
    $controlsLayout->addWidget(this->valueSpinBox, 2, 1);
    $controlsLayout->addWidget(this->valueFineSpinBox, 3, 1);
    this->controlsGroup->setLayout($controlsLayout);
}


1;
