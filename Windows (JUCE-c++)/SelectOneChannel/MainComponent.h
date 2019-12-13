/*
  ==============================================================================

	This file was auto-generated!

  ==============================================================================
*/

#pragma once

#include "../JuceLibraryCode/JuceHeader.h"
#include <Winsock2.h>


//==============================================================================
/*
	This component lives inside our window, and this is where you should put all
	your controls and content.
*/
class MainComponent : public AudioAppComponent, public Thread


{
public:


	//==============================================================================
	MainComponent();
	~MainComponent();

	void run();



	//==============================================================================
	void prepareToPlay(int samplesPerBlockExpected, double sampleRate) override;
	void getNextAudioBlock(const AudioSourceChannelInfo& bufferToFill) override;
	void releaseResources() override;

	//==============================================================================
	void paint(Graphics& g) override;
	void resized() override;


	Label inputText1;
	Label inputText2;
	Label portDisplay;
	Label portStatus;
	Label info;

	double amp1;
	double amp2;

	int port1;
	DatagramSocket sock1;
	int port2;
	DatagramSocket sock2;

	ToggleButton toggle;


private:
	//==============================================================================
	// Your private member variables go here...


	int startS;




	double sampleRate = 0.0;
	int expectedSamplesPerBlock = 0;
	int bytes = 0;

	int iterations = 0;


	double currentSampleRate = 0.0, currentAngle = 0.5, angleDelta = 0.1;
	String scheck;

	AudioDeviceManager::AudioDeviceSetup adsetup;
	AudioIODevice* device;
	Array<double> rates;





	JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MainComponent)
};


