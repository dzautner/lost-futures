Engine_LostFutures : CroneEngine {
  var pg;
  var amp=0.3;
  var attack=0.1;
  var decay=1.0;
  var sustain=5.0;
  var release=1.8;
  var gate=1;
  var vol=0.2;
  var pw=0.5;
  var cutoff=300;
  var envMul=1000;
  var gain=2;
  var wave=0;
  var dec=1.0;
  var resonance=0.2;
  var notes;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    notes = Dictionary.new;
    pg = ParGroup.tail(context.xg);
    SynthDef("WannabeTB303", {
      arg out, freq = 440, pw=pw, amp=amp, cutoff=cutoff, gain=gain, release=release, attack=attack, sustain=sustain, gate=gate, envMul=envMul, dec=dec, wave=wave, resonance=resonance;

      var env = EnvGen.ar(Env.asr(attackTime: attack, sustainLevel: sustain, releaseTime: release), gate: gate, doneAction: Done.freeSelf);
      var waves = [Saw.ar(freq, mul: env), Pulse.ar(freq, 0.5, mul: env)];
      var filterEnv =  EnvGen.ar( Env.new([10e-10, 1, 10e-10], [0.01, dec],  'exp'), gate, doneAction: Done.freeSelf);
      var filter = RLPF.ar(Select.ar(wave, waves), cutoff + (filterEnv * envMul), resonance).dup;
      Out.ar(out, filter * amp);

    }).add;

    this.addCommand("noteOn", "f", { arg msg;
      var val = msg[1];
      notes.put(val, Synth("WannabeTB303", [\out, context.out_b, \freq,val,\pw,pw,\amp,amp,\cutoff,cutoff,\gain,gain,\release,release,\attack,attack,\sustain,sustain,\gate,gate,\envMul,envMul,\dec,dec,\wave,wave,\resonance,resonance], target:pg));
    });

    this.addCommand("noteOff", "f", { arg msg;
      var val = msg[1];
      var note = notes.at(val);
      note.set(\gate, 0);
      notes.removeAt(val);
    });

    this.addCommand("gate", "f", { arg msg;
      gate = msg[1];
    });
  
    this.addCommand("amp", "f", { arg msg;
      amp = msg[1];
    });

    this.addCommand("pw", "f", { arg msg;
      pw = msg[1];
    });

    this.addCommand("attack", "f", { arg msg;
      attack = msg[1];
    });
    
    this.addCommand("sustain", "f", { arg msg;
      sustain = msg[1];
    });
    
    this.addCommand("release", "f", { arg msg;
      release = msg[1];
    });
    
    this.addCommand("cutoff", "f", { arg msg;
      cutoff = msg[1];
      notes.do { |item, i| item.set(\cutoff, cutoff) };
    });
    
    this.addCommand("gain", "f", { arg msg;
      gain = msg[1];
    });

    this.addCommand("env", "f", { arg msg;
      envMul = msg[1];
    });

    this.addCommand("dec", "f", { arg msg;
      dec = msg[1];
    });
    
    this.addCommand("wave", "f", { arg msg;
      wave = msg[1];
    });
    
    this.addCommand("resonance", "f", { arg msg;
      resonance = msg[1];
    });

  }
}