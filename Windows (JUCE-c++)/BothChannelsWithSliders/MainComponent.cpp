/*
  ==============================================================================

    This file was auto-generated!

  ==============================================================================
*/

#include "MainComponent.h"
#include <chrono> 


//==============================================================================



template<typename FloatType>
class AudioBufferFIFO
{
public:
	AudioBufferFIFO(int channels, int buffersize) :
		fifo(buffersize)
	{
		buffer.setSize(channels, buffersize);
	}

	void addToFifo(const FloatType** samples, int numSamples)
	{
		//jassert(getFreeSpace() > numSamples);
		int start1, size1, start2, size2;
		fifo.prepareToWrite(numSamples, start1, size1, start2, size2);
		if (size1 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				buffer.copyFrom(channel, start1, samples[channel], size1);
		if (size2 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				buffer.copyFrom(channel, start2, samples[channel] + size1, size2);
		fifo.finishedWrite(size1 + size2);
	}

	void addToFifo(const juce::AudioBuffer<FloatType>& samples, int numSamples = -1)
	{
		const int addSamples = numSamples < 0 ? samples.getNumSamples() : numSamples;
		//jassert(getFreeSpace() > addSamples);

		int start1, size1, start2, size2;
		fifo.prepareToWrite(addSamples, start1, size1, start2, size2);
		if (size1 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				buffer.copyFrom(channel, start1, samples.getReadPointer(channel), size1);
		if (size2 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				buffer.copyFrom(channel, start2, samples.getReadPointer(channel, size1), size2);
		fifo.finishedWrite(size1 + size2);

	}

	void readFromFifo(FloatType** samples, int numSamples)
	{
		//jassert(getNumReady() > numSamples);
		int start1, size1, start2, size2;
		fifo.prepareToRead(numSamples, start1, size1, start2, size2);
		if (size1 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				juce::FloatVectorOperations::copy(samples[channel],
					buffer.getReadPointer(channel, start1),
					size1);
		if (size2 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				juce::FloatVectorOperations::copy(samples[channel] + size1,
					buffer.getReadPointer(channel, start2),
					size2);
		fifo.finishedRead(size1 + size2);
	}

	void readFromFifo(juce::AudioBuffer<FloatType>& samples, int numSamples = -1)
	{
		const int readSamples = numSamples > 0 ? numSamples : samples.getNumSamples();
		jassert(getNumReady() >= readSamples);

		int start1, size1, start2, size2;
		fifo.prepareToRead(readSamples, start1, size1, start2, size2);
		if (size1 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				samples.copyFrom(channel, 0, buffer.getReadPointer(channel, start1), size1);
		if (size2 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				samples.copyFrom(channel, size1, buffer.getReadPointer(channel, start2), size2);
		fifo.finishedRead(size1 + size2);
	}

	void readFromFifo(const juce::AudioSourceChannelInfo& info, int numSamples = -1)
	{
		const int readSamples = numSamples > 0 ? numSamples : info.numSamples;
		//jassert(getNumReady() >= readSamples);

		int start1, size1, start2, size2;
		fifo.prepareToRead(readSamples, start1, size1, start2, size2);
		if (size1 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				info.buffer->copyFrom(channel, info.startSample, buffer.getReadPointer(channel, start1), size1);
		if (size2 > 0)
			for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
				info.buffer->copyFrom(channel, info.startSample + size1, buffer.getReadPointer(channel, start2), size2);
		fifo.finishedRead(size1 + size2);
	}

	int getNumChannels() const {
		return buffer.getNumChannels();
	}

private:
	juce::AbstractFifo  fifo;

	/*< The actual audio buffer */
	juce::AudioBuffer<FloatType>    buffer;
};

AudioBufferFIFO<float> abuffer(1, 3840);
AudioBufferFIFO<float> abuffer2(1, 3840);



MainComponent::MainComponent() : Thread("UDP Thread")
	
{
	amp1 = 0;
	amp2 = 0;

	addAndMakeVisible(amp1Slider);
	amp1Slider.setRange(0, 1, 0.01);          // [1]
	amp1Slider.setTextValueSuffix(" Amplitude");     // [2]
	amp1Slider.addListener(this);             // [3]

	addAndMakeVisible(amp1Label);
	amp1Label.setText("Amplitude 1", dontSendNotification);
	amp1Label.attachToComponent(&amp1Slider, true); // [4]

	addAndMakeVisible(amp2Slider);
	amp2Slider.setRange(0, 1, 0.01);          // [1]
	amp2Slider.setTextValueSuffix(" Amplitude");     // [2]
	amp2Slider.addListener(this);             // [3]

	addAndMakeVisible(amp2Label);
	amp2Label.setText("Amplitude 2", dontSendNotification);
	amp2Label.attachToComponent(&amp2Slider, true); // [4]

	addAndMakeVisible (inputText1);
    inputText1.setEditable (true);
    inputText1.setColour (Label::backgroundColourId, Colours::darkblue);

	addAndMakeVisible(inputText2);
	inputText2.setEditable(true);
	inputText2.setColour(Label::backgroundColourId, Colours::darkblue);

	addAndMakeVisible(portDisplay);
	portDisplay.setText("Portnumber = X:", dontSendNotification);
	portDisplay.setJustificationType(Justification::right);
	portDisplay.attachToComponent(&inputText1, true);

	addAndMakeVisible(portStatus);
	portStatus.setText("not bound", dontSendNotification);

	addAndMakeVisible(info);
	info.setText("info", dontSendNotification);

	
	inputText1.onTextChange = [this] {port1 = (inputText1.getText().getIntValue());
		String str = "Port = ";
		String prt = std::to_string(port1);
		str += prt;

		portDisplay.setText(str ,dontSendNotification);
		bool succes = sock1.bindToPort(port1);
		if (succes) { portStatus.setText("Bind1 succesful", dontSendNotification); }
		else { portStatus.setText("Bind1 Failed", dontSendNotification); }
;
	};

	inputText2.onTextChange = [this] {port2 = (inputText2.getText().getIntValue());
	String str = "Port = ";
	String prt = std::to_string(port2);
	str += prt;

	portDisplay.setText(str, dontSendNotification);
	bool succes = sock2.bindToPort(port2);
	if (succes) { portStatus.setText("Bind2 succes", dontSendNotification); }
	else { portStatus.setText("Bind2 Failed", dontSendNotification); }
	;
	};
	
	
	
	
	// Make sure you set the size of the component after
    // you add any child components.
    setSize (800, 600);

    {
        // Specify the number of input and output channels that we want to open
        setAudioChannels (0,2);
		device = deviceManager.getCurrentAudioDevice();
		adsetup = deviceManager.getAudioDeviceSetup();
		adsetup.sampleRate = 48000;
		scheck = deviceManager.setAudioDeviceSetup(adsetup, true);
		rates = device->getAvailableSampleRates();
    }

	startThread(10);
	

}



MainComponent::~MainComponent()
{
    // This shuts down the audio device and clears the audio source.
    shutdownAudio();
	stopThread(300);
}

void MainComponent::run()
{
	AudioBuffer <float> udpBuffer;
	udpBuffer = juce::AudioBuffer<float>(1, 9600);
	udpBuffer.clear();
	while (!threadShouldExit())
	{
		//FOR CHANNEL2
		sock2.read((void*)udpBuffer.getWritePointer(0, 0), 7680, true);
		udpBuffer.applyGain(0.0000625f);
		udpBuffer.applyGain(amp2);
		abuffer2.addToFifo(udpBuffer, 1920);

		//sock.waitUntilReady(true, 1000);
		//FOR CHANNEL1
		sock1.read((void*)udpBuffer.getWritePointer(0,0), 7680, true);
		udpBuffer.applyGain(0.0000625f);
		udpBuffer.applyGain(amp1);
		abuffer.addToFifo(udpBuffer,1920);
		
		
	}
	ExitThread;
}


void MainComponent::sliderValueChanged(Slider* slider)
{
	if (slider == &amp1Slider)
		amp1 = amp1Slider.getValue();
	else if (slider == &amp2Slider)
		amp2 = amp2Slider.getValue();
	
}

//==============================================================================
void MainComponent::prepareToPlay (int samplesPerBlockExpected, double newSampleRate)
{
    // This function will be called when the audio device is started, or when
    // its settings (i.e. sample rate, block size, etc) are changed.

    // You can use this function to initialise any resources you might need,
    // but be careful - it will be called on the audio thread, not the GUI thread.

    // For more details, see the help for AudioProcessor::prepareToPlay()

	sampleRate = newSampleRate;
	expectedSamplesPerBlock = samplesPerBlockExpected;

}

void MainComponent::getNextAudioBlock (const AudioSourceChannelInfo& bufferToFill)
{
    // Your audio-processing code goes here!

    // For more details, see the help for AudioProcessor::getNextAudioBlock()

    // Right now we are not producing any data, in which case we need to clear the buffer
    // (to prevent the output of random noise)
    bufferToFill.clearActiveBufferRegion();
	

	auto* leftBuffer = bufferToFill.buffer->getWritePointer(0, bufferToFill.startSample);
	auto* rightBuffer = bufferToFill.buffer->getWritePointer(1, bufferToFill.startSample);

	//auto* udpB = udpBuffer.getReadPointer(0, startS);

	//sock.waitUntilReady(true, 100);
	//sock.read(bfr, (bufferToFill.buffer->getNumSamples()*2), false);

	//bytes = bufferToFill.buffer->getNumSamples();
	
	//endianConvert(bufferToFill.buffer->getNumSamples());
	
	abuffer.readFromFifo(&leftBuffer, bufferToFill.buffer->getNumSamples());
	abuffer2.readFromFifo(&rightBuffer, bufferToFill.buffer->getNumSamples());

}

void MainComponent::releaseResources()
{
    // This will be called when the audio device stops, or when it is being
    // restarted due to a setting change.

    // For more details, see the help for AudioProcessor::releaseResources()
}

//==============================================================================
void MainComponent::paint (Graphics& g)
{
	deviceManager.getAudioDeviceSetup(adsetup);
	

    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll(Colour(0.7f, 0.7f, 0.5f, 1.0f));
    // You can add your drawing code here!
	info.setText((String)rates[0] + "  "+(String)port1 + "   ",dontSendNotification);
}

void MainComponent::resized()
{
    // This is called when the MainContentComponent is resized.
    // If you add any child components, this is where you should
    // update their positions.

	inputText1.setBounds(100, 50, getWidth() - 110, 20);
	inputText2.setBounds(100, 70, getWidth() - 110, 20);
	portStatus.setBounds(100,100, getWidth() - 110, 20);
	info.setBounds(100, 200, getWidth() - 110, 20);
	amp1Slider.setBounds(100, 300, getWidth() - 110, 20);
	amp2Slider.setBounds(100, 400, getWidth() - 110, 20);
}


