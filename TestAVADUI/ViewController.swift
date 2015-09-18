//
//  ViewController.swift
//  TestAVADUI
//
//  Created by James Tyner on 9/17/15.
//  Copyright © 2015 James Tyner. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {
    let engine = AVAudioEngine()
    @IBOutlet weak var freqLabel: UILabel!
    let pi = M_PI
    let bus = 0
    var C2 = 65.41; // C2 note, in Hz.
    var notes = [ "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" ];
    var test_frequencies = [NoteInfo]();

    var buffer = [];
    var sample_length_milliseconds = 100;
    var recording = true;
    var timer:NSTimer?
    var theBuffer = [Double]()
    var samplesAsDoubles: [Double] = []
    var dominant_frequency:NoteInfo?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupFrequencies()
        let inputNode = engine.inputNode
        let sampleCount = 1024
        samplesAsDoubles = Array(count: Int(sampleCount), repeatedValue: CDouble())
        let frameLength = UInt32(sampleCount) // This seems to be ignored when passed into the AudioTap, therefore reassign within block.  
        inputNode!.installTapOnBus(bus, bufferSize: frameLength, format:inputNode!.inputFormatForBus(bus)) {
                (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in

            buffer.frameLength = UInt32(sampleCount)
            
            // Populate array with incomming audio samples
            for var i = 0; i < Int(buffer.frameLength); i++
            {
                self.samplesAsDoubles[i] = Double(buffer.floatChannelData.memory[i])
            }
            self.interpret_correlation_result(self.samplesAsDoubles, testFrequencies: self.test_frequencies, theSampleRate: 44100)
           
        }
        
            engine.prepare()
        do {
          try engine.start()
        } catch {
           print("ERROR MATE")
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(0.250, target: self, selector: Selector("updateTextView:"), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    func setupFrequencies(){
        for (var i = 0; i < 30; i++)
        {
            let note_frequency = C2 * pow(2.0, Double(i) / 12.0)
            let note_name = notes[i % 12]
            let note = NoteInfo(theFrequency: note_frequency, theNoteName: note_name)
            let just_above = NoteInfo(theFrequency: note_frequency * pow(2, 1 / 48), theNoteName: note_name + " (a bit sharp)")
            let just_below = NoteInfo(theFrequency: note_frequency * pow(2, -1 / 48), theNoteName: note_name + " (a bit flat)")
            test_frequencies.append(just_below)
            test_frequencies.append(note)
            test_frequencies.append(just_above)
        }
    }
    
    func interpret_correlation_result(theTimeSeries: [Double], testFrequencies: [NoteInfo], theSampleRate: Double)
    {
        let ts = theTimeSeries
        let tf = testFrequencies
        let sr = theSampleRate

    let frequency_amplitudes = compute_correlations(ts, test_frequencies: tf, sample_rate: sr)
    // Compute the (squared) magnitudes of the complex amplitudes for each
    // test frequency.
    var magnitudes = frequency_amplitudes.map { z in
        return z[0] * z[0] + z[1] * z[1];
        }
    
    // Find the maximum in the list of magnitudes.
    var maximum_index = -1;
    var maximum_magnitude = 0.0
    for (var i = 0; i < magnitudes.count; i++)
    {
        if (magnitudes[i] <= maximum_magnitude){
           continue;
        }
    maximum_index = i;
    maximum_magnitude = magnitudes[i];
    }
    // Compute the average magnitude. We'll only pay attention to frequencies
    // with magnitudes significantly above average.
    //var average = magnitudes.reduce(function(a, b) { return a + b; }, 0) / magnitudes.length;
    let average = magnitudes.reduce(0) { (a, b) in a + b } / Double(magnitudes.count)
        
    let confidence = maximum_magnitude / average;
    let confidence_threshold = 10.0; // empirical, arbitrary.
    if (confidence > confidence_threshold)
    {
    dominant_frequency = test_frequencies[maximum_index]
    //print(dominant_frequency?.getNoteName())
    //timer.start()
        
    }
    }
    
    func updateTextView(_: NSTimer){
        if let frequency = dominant_frequency?.getNoteName(){
           
               freqLabel.text = frequency
        }
        //print(dominant_frequency?.getNoteName())
    }
    
    func compute_correlations(timeseries:[Double], test_frequencies:[NoteInfo], sample_rate:Double) -> [[Double]]
    {
    // 2pi * frequency gives the appropriate period to sine.
    // timeseries index / sample_rate gives the appropriate time coordinate.
    let scale_factor = 2 * pi / sample_rate;
    let amplitudes: [[Double]]   = test_frequencies.map { f  in

    let frequency = f.getFrequency()
    
    // Represent a complex number as a length-2 array [ real, imaginary ].
    var accumulator: [Double] = [ 0.0, 0.0 ]
    for (var t = 0; t < timeseries.count; t++)
    {
				accumulator[0] += timeseries[t] * cos(scale_factor * frequency * Double(t))
				accumulator[1] += timeseries[t] * sin(scale_factor * frequency * Double(t))
    }
    
    return accumulator
        
    }

    
    return amplitudes;
    }
    
}

