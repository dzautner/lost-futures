-- lost futures
-- v1.0 @dzautner
--
-- bass synth in the style of the rb303
-- 
-- k2 - previous control panel
-- k3 - next control panel
-- e1, e2, e3 - control the paramters in the control panel in focus

engine.name = 'LostFutures'

local EnvGraph = require "envgraph"
local UI = require "ui"

local midi_signal_in
local viewport = { width = 128, height = 64 }

-- Synth Params
local asr = { attack = 0.1, sustain = 5.0, release = 0.8 }

local cutoff = 300
local env = 1000
local dec = 1.0
local amp = 0.3
local vol = 0
local resonance = 0.2
local wave = 0

local focus = 1

-- Main

function init()
  connect()
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  -- Render
  redraw()
end


function connect()
  midi_signal_in = midi.connect(1)
  midi_signal_in.event = on_midi_event
end

function on_midi_event(data)
  msg = midi.to_msg(data)
  play(msg)
end

function play(msg)
  if msg.type == 'note_on' then
    hz = note_to_hz(msg.note)
    engine.amp(vol + (msg.vel / 127))
    engine.noteOn(hz)
    amplitude = msg.note - 50
  elseif msg.type == 'note_off' then
    hz = note_to_hz(msg.note)
    engine.noteOff(hz)
  end
end

function key(id,state)
  if id == 3 and state == 1 then
    if focus == 3 then focus = 0 end
    focus = focus + 1
  end
  if id == 2 and state == 1 then
    if focus == 1 then focus = 4 end
    focus = focus - 1
  end
end

function enc(id,delta)
  -- ASR
  if focus == 1 then
    if id == 1 then
      asr.attack = clamp(asr.attack + delta/10, 0, 10)
      engine.attack(asr.attack)
    elseif id == 2 then
      asr.sustain = clamp(asr.sustain + delta/10, 0, 10)
      engine.sustain(asr.sustain)
    elseif id == 3 then
      asr.release = clamp(asr.release + delta/10, 0, 10)
      engine.release(asr.release)
    end
  
  -- Filter
  elseif focus == 2 then
    -- Cutoff
    if id == 1 then
      cutoff = clamp(cutoff + (delta * 10), 0, 9000)
      engine.cutoff(cutoff)
    -- FilterEnv
    elseif id == 2 then
      env = clamp(env + (delta * 10), 0, 9000)
      engine.env(env)
    -- Dec
    elseif id == 3 then
      dec = clamp(dec + (delta / 10), 0, 100)
      engine.dec(dec)
    end
  
  -- Misc
  elseif focus == 3 then
    -- Wave type
    if id == 1 then
      wave = clamp(wave + delta, 0, 1)
      engine.wave(wave)
    -- BOOST
    elseif id == 2 then
      vol = clamp(vol + delta/10, 0, 10)
    -- Resonance
    elseif id == 3 then
      resonance = clamp(resonance + (delta/10), 0, 1)
      engine.resonance(resonance)
    end
  end

end

local foreground_x = 0

function draw_art()
  if foreground_x >= viewport.width then
    foreground_x = 0
  else
    foreground_x = foreground_x + (1 * (cutoff/300))
  end
  screen.display_png(_path.this.path.."art/bg.png", 0, 0)
  screen.display_png(_path.this.path.."art/far_buildings.png", foreground_x/2, 0)
  screen.display_png(_path.this.path.."art/far_buildings.png", foreground_x/2-viewport.width, 0)
  screen.display_png(_path.this.path.."art/foreground.png", foreground_x, 0)
  screen.display_png(_path.this.path.."art/foreground.png", foreground_x-viewport.width, 0)
end

function draw_saw()
  screen.aa(1)
  screen.line_width(2)
  screen.move(4,55)
  screen.line(14,45)
  screen.line(14,57)
  screen.line(24,45)
  screen.line(24,57)
  screen.line(34,45)
  screen.stroke()
end

function draw_pulse()
  screen.aa(0)
  screen.line_width(2)
  screen.move(4,60)
  screen.line(14,60)
  screen.line(14,50)
  screen.line(24,50)
  screen.line(24,60)
  screen.line(34,60)
  screen.stroke()
  screen.line_width(1)
end

function draw_env()
  demo_graph = EnvGraph.new_asr(0, 10, 0, 10, asr.attack, asr.release, asr.sustain, asr.r, 1, 1)
  demo_graph:set_position_and_size(4, 4, 32, 16)
  demo_graph:redraw()
  screen.level(15)
  screen.line_width(1)

  if focus == 1 then
    screen.rect(1, 0, 40, 24)
    screen.stroke()

  elseif focus == 2 then
    screen.rect(44, 0, 80, 24)
    screen.stroke()

  elseif focus == 3 then
    screen.rect(1, 38, 87, 24)
    screen.stroke()
  end

end

function draw_ui()
  co_ui = UI.Dial.new(50, 2, 13, cutoff/10, 0, 100, 1, 0, nil, nil, "cut")
  env_ui = UI.Dial.new(76, 2, 13, env/10, 0, 300, 1, 0, nil, nil, "env")
  dec_ui = UI.Dial.new(99, 2, 13, dec, 0, 10, 0, 0, nil, nil, "dec")

  boost_ui = UI.Dial.new(45, 41, 13, vol, 0, 10, 0, 0, nil, nil, "bst")
  res_ui = UI.Dial.new(71, 41, 13, resonance, 0, 1, 0, 0, nil, nil, "res")

  co_ui:redraw()
  env_ui:redraw()
  dec_ui:redraw()

  boost_ui:redraw()
  res_ui:redraw()

  if wave == 0 then
    draw_saw()
  else 
    draw_pulse()
  end
end

function redraw()
  screen.clear()
  draw_art()
  draw_env()
  draw_ui()
  screen.update()
end

-- Utils

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end

-- Interval

re = metro.init()
re.time = 1.0 / 15
re.event = function()
  redraw()
end
re:start()
-- Utils

function clamp(val,min,max)
  return val < min and min or val > max and max or val
end

function note_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end
