%% MatSynth by Ryhmä 8   #Sodis 2020 syksy
%  contact: juuso.o.korhonen@aalto.fi, mikko.seppi@aalto.fi,
%  arttu.pitkanen@aalto.fi
%  ------------------------------------------------------------------------
% Virtuaalianalogisen synteesin toteuttava audio-ohjelma
% Voit muokata ääntä GUI:sta löytyvillä säädöillä
% ja soittaa joko hiirellä, näppäimistöllä tai liitetyllä MIDI-laitteella

%% GUIn luonti ja default arvot säädöille
function MatSynthesizer
    clf; clear; close all; clc;
    global Synth
    
    Name                    = 'Syntikka';
    Version                 = 1.0;
    
    %% Tones
    RefTone                 = 440;                                      % [Hz] - reference tone (A)
    ToneId                  = -9:27;                                    % with respect to reference tone (0-A) (e.g. [-2,-1,0,1] means [G G# A A#])
    ToneName                = {'C' 'C#' 'D' 'D#' 'E' 'F' 'F#' 'G' 'G#' 'A' 'A#' 'B'};
    Synth.Tones.Fs          = 44100;%16384;                                    % [Hz] - sampling frequency 
    Synth.Tones.Frequency   = RefTone * 2.^(ToneId/12);                 % table of frequencies [Hz]
    Synth.Keyboard          = {'z' 'x' 'd' 'c' 'f' 'v' 'b' 'h' 'n' 'j' 'm' 'k' 'comma' 'period' 'semicolon' 'slash'};   % defines keyboard (Matlab notation)
    KeyboardMarker          = {'z' 'x' 'd' 'c' 'f' 'v' 'b' 'h' 'n' 'j' 'm' 'k' ','     '.'      ';'         '/'};
    Synth.Tones.Sample      = cell(size(ToneId));
    %% Keys
    Key(1)                  = struct('X',[-0.5 0.5 0.5 -0.5], 'Y',[0 0 3 3], 'Color','white');
    Key(2)                  = struct('X',[-0.4 0.4 0.4 -0.4], 'Y',[1 1 3 3], 'Color','black');
    KeyName                 = ToneName(mod(ToneId+9,12)+1);
    KeyColorId              = cellfun(@(x) (length(x)==2)+1, KeyName);  % 1-white, 2-black
    Synth.KeyboardToneId    = (1-length(Synth.Keyboard):0) + find(strcmp(KeyName,'D'),1,'last');    % 'slash' = first D from the left side
                      
    %% Board
    KeyScale        = 40;                                               % change this value to resize Synth
    Size            = [sum(KeyColorId==1)+1, 4] * KeyScale + [0 60];    % depends on number of white keys
    Color           = [0.8 0.8 0.9];
    BackgroundColor = [0.4 0.4 0.8];
    %% Application window
 
    
    ScreenSize = get(0,'ScreenSize');
    figure( 'Units','pixels',...
            'Renderer','painters',...
            'Position',[(ScreenSize(3:4) - Size)*0.5, Size] + [0 0 10 27],...
            'MenuBar','none',...
            'NumberTitle','off',...
            'Resize','off',...
            'Color',BackgroundColor,...
            'Name',[Name],...
            'KeyPressFcn',@(~,evt)KeyPress(evt.Key));
    axes( 'Units','pixels',...
          'Position',[5 5 Size],...
          'NextPlot','add',...
          'box','on',...
          'Color',Color,...
          'xlim',[0 Size(1)],...
          'ylim',[0 Size(2)],...
          'XTick',[],...
          'YTick',[]);
 
    title(sprintf('%s v%0.1f', Name, Version));
    %% Create keyboard
    nTone           = length(ToneId);
    KeyBoard(nTone) = matlab.graphics.primitive.Patch;
    X = KeyScale;
    for i = 1:nTone
        cid = KeyColorId(i);
        x = X + (Key(cid).X - (cid==2)*0.5)*KeyScale;
        y = 5 + Key(cid).Y*KeyScale;
        KeyBoard(i) = patch(x,y,Key(cid).Color,'ButtonDownFcn',@(~,~)MousePress(i));
        if (cid==1), uistack(KeyBoard(i),'bottom'); end
        text(mean(x(1:2)),y(1)+12,KeyName{i},'Color',Key(3-cid).Color,'HorizontalAlignment','center','PickableParts','none');
        id = find(Synth.KeyboardToneId==i);
        if ~isempty(id)
            text(mean(x(1:2)),y(1)+30,KeyboardMarker{id},'Color',[0.5 0.5 0.5],'HorizontalAlignment','center','PickableParts','none');
        end
        X = X + (cid==1)*KeyScale;
    end
   
    text([120;120;120],Size(2)-[15;35;55],{'shape:','amplitude profile:', 'effect:'},'HorizontalAlignment','right','FontWeight','bold');
    Synth.hShape     = text((130:90:670)',ones(7,1)*(Size(2)-15),{'sinus','square','triangle','3 sin','pwm','sin vibrato', 'sawtooth'},'ButtonDownFcn',@(src,~)ChangeShape(src));
    Synth.hAmplitude = text((130:90:220)',ones(2,1)*(Size(2)-35),{'constant','ADSR'},'ButtonDownFcn',@(src,~)ChangeAmplitude(src));
    Synth.hEffect = text((130:90:310)',ones(3,1)*(Size(2)-55),{'tremolo','ripple', 'none'},'ButtonDownFcn',@(src,~)ChangeEffect(src));
    
    %% Säätimet ja niiden herätefunktioiden asettaminen

   fig = uifigure('Name','Sliders', 'Position',[100 100 700 500]);
    Synth.DCA_amp = uislider(fig,...
        'Position',[100 75 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    Synth.DCA_amp.Limits = [0 5];
    Synth.DCA_amp.MajorTicks = [Synth.DCA_amp.Limits(1) Synth.DCA_amp.Limits(2)];
    Synth.DCA_amp.Value = 1;
    
    
    %title
    Slider_Label = uilabel('Parent',fig);
    Slider_Label.Text = "Amplitude";
    Slider_Label.Position = [100 80 120 33];
    
    
    
    
    Synth.LFO_f = uislider(fig,...
        'Position',[100 150 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    Synth.LFO_f.Limits = [0 10];
    Synth.LFO_f.MajorTicks = [Synth.LFO_f.Limits(1) Synth.LFO_f.Limits(2)];
    Synth.LFO_f.Value = 4;
    
    %title
    Slider_Label2 = uilabel('Parent',fig);
    Slider_Label2.Text = "LFO frequency";
    Slider_Label2.Position = [100 155 120 33];
    
    
    
    
    Synth.f_cut = uislider(fig,...
        'Position',[100 225 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    Synth.f_cut.Limits = [0.1 Synth.Tones.Fs/2-0.1];
    Synth.f_cut.MajorTicks = [Synth.f_cut.Limits(1) Synth.f_cut.Limits(2)];
    Synth.f_cut.Value = 1024;
    
   
    Slider_Label3 = uilabel('Parent',fig);
    Slider_Label3.Text = "Cutoff frequency";
    Slider_Label3.Position = [100 230 120 33];
    
    Synth.Duration = uislider(fig,...
        'Position',[100 300 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    Synth.Duration.Limits = [0.1 5];    
    Synth.Duration.MajorTicks = [Synth.Duration.Limits(1) Synth.Duration.Limits(2)];
    Synth.Duration.Value = 0.5;
    
    
    %title
    Slider_Label4 = uilabel('Parent',fig);
    Slider_Label4.Text = "Duration";
    Slider_Label4.Position = [100 305 120 33];

    
    Synth.Attack = uislider(fig,...
        'Position',[275 440 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    Synth.Attack.Limits = [0.1 1];
    Synth.Attack.MajorTicks = [Synth.Attack.Limits(1) Synth.Attack.Limits(2)];
    Synth.Attack.Value = 0.25;
    
    %title
    Slider_Label5 = uilabel('Parent',fig);
    Slider_Label5.Text = "Attack";
    Slider_Label5.Position = [275 445 120 33];
    
    
    Synth.Decay = uislider(fig,...
        'Position',[275 380 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    Synth.Decay.Limits = [0.1 1];
    Synth.Decay.MajorTicks = [Synth.Decay.Limits(1) Synth.Decay.Limits(2)];
    Synth.Decay.Value = 0.25;
    
    %title
    Slider_Label6 = uilabel('Parent',fig);
    Slider_Label6.Text = "Decay";
    Slider_Label6.Position = [275 385 120 33];
    
    Synth.Sustain = uislider(fig,...
        'Position',[500 440 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    
    Synth.Sustain.Limits = [0.1 1];
    Synth.Sustain.MajorTicks = [Synth.Sustain.Limits(1) Synth.Sustain.Limits(2)];
    Synth.Sustain.Value = 0.25;
    
    Slider_Label6 = uilabel('Parent',fig);
    Slider_Label6.Text = "Sustain";
    Slider_Label6.Position = [500 445 120 33];
    
    Synth.Release = uislider(fig,...
        'Position',[500 380 120 3],...
        'ValueChangedFcn',@(sld,event) CreateSamples());
    
    Synth.Release.Limits = [0.1 1];
    Synth.Release.MajorTicks = [Synth.Release.Limits(1) Synth.Release.Limits(2)];
    Synth.Release.Value = 0.25;
    
    Slider_Label7 = uilabel('Parent',fig);
    Slider_Label7.Text = "Release";
    Slider_Label7.Position = [500 385 120 33];

    Synth.PlotTypeSwitch = uiswitch(fig,'toggle',...
    'Items',{'Pulse','Spectrum'},...    
    'Position',[115 375 20 45],...
    'ValueChangedFcn',@(sld,event) updatePlot());
        
    % MIDI SWITCH

    Synth.MidiSwitch = uiswitch(fig,'toggle',...
    'Items',{'MIDI On', 'MIDI Off'},...    
    'Position',[175 375 20 45],...
    'ValueChangedFcn',@(sld,event) updateMidi());

    Synth.MidiSwitch.Value = 'MIDI Off';

    %% Plot
    Synth.Plot = uiaxes('Parent',fig);
    Plot_X_Position = 250;
    Plot_Y_Position = 50;
    HPlot_Height = 300;
    Plot_Width = 400;
    Synth.Plot.Position = [Plot_X_Position Plot_Y_Position Plot_Width HPlot_Height];
    Synth.Plot.GridColor = [0.15 0.15 0.15];
    Synth.Plot.XGrid = 'on';
    Synth.Plot.YGrid = 'on';
    Synth.Plot.ZGrid = 'on';

    %plot(Synth.Plot,[]);
   
    %% Initial settings
    Synth.Effect            = 1;    
    Synth.ToneShapeId       = 1;
    Synth.ToneAmplitudeId   = 1;
    Synth.samples = zeros(1, 1000);
    drawnow;
    CreateSamples();
end
%% Säädinten herätefunktiot
function ChangeShape(src)
    global Synth
    Synth.ToneShapeId = find(Synth.hShape==src);
    CreateSamples();
end
function ChangeAmplitude(src)
    global Synth
    Synth.ToneAmplitudeId = find(Synth.hAmplitude==src);
    CreateSamples();
end

function ChangeEffect(src)
    global Synth
    Synth.Effect = find(Synth.hEffect==src);
    CreateSamples();
end
%% Synteesi
% Tämä funktio on vastuussa synteesiprosessista, se luo näytteet käyttäjän GUIsta antamien arvojen mukaan
% (oskillaattorityyppi, amplitudiprofiili, efekti + säädinarvot) jokaiselle koskettimen kielelle    
function CreateSamples()
    global Synth
    set([Synth.hShape; Synth.hAmplitude; Synth.hEffect],'Color','black');
    set([Synth.hShape(Synth.ToneShapeId); Synth.hAmplitude(Synth.ToneAmplitudeId); Synth.hEffect(Synth.Effect)],'Color','yellow');
    %% Äänen kesto
    T   = (Synth.Attack.Value + Synth.Decay.Value + Synth.Sustain.Value + Synth.Release.Value) * Synth.Duration.Value;                                      
    %% Amplitudiprofiilin valinta
    switch Synth.ToneAmplitudeId
        case 1                                      % constant
            Amp = linspace(1,1,Synth.Tones.Fs*T);
        case 2
            % ADSR
            Amp = ADSR(T, Synth.Tones.Fs, (Synth.Attack.Value* Synth.Duration.Value)/T, (Synth.Decay.Value* Synth.Duration.Value)/T, (Synth.Sustain.Value* Synth.Duration.Value)/T, (Synth.Release.Value* Synth.Duration.Value)/T);
    end
    %% Oskillaattorin valinta
    t = linspace(0,T,Synth.Tones.Fs*T);
    for i=1:length(Synth.Tones.Sample)
        a = 2*pi*Synth.Tones.Frequency(i)*t;
        switch Synth.ToneShapeId
            case 1                                  % sini
                s = sin(a);
            case 2                                  % kantti
                s = (2*(sin(a)>0)-1)*0.6;
            case 3                                  % kolmio
                N = 1:2:13;
                s = sum(sin(N'*a).^2 .* ((4/pi./N)'.^2*ones(size(t)))) - 1;
            case 4                                  % 3 sin
                s = 0.6*sin(a) + 0.3*sin(a*2) +0.1*sin(a*4);
            case 5                                  % pwm
                q = linspace(0,1,Synth.Tones.Fs*T);
                s = (2*((sin(a)+q)>0)-1)*0.6;
            case 6                                  % vibrato
                q = sin(2*pi*4*t)*0.001;
                s = sin(a+2*pi*Synth.Tones.Frequency(i)*q);
            case 7                                  % detunattu sawtooth
                s = sawtooth(a) + sawtooth(1.001*a) + sawtooth(1.002*a) + sawtooth(0.999*a);
        end
        %% LFO-efektin valinta
        switch Synth.Effect
            case 1
                f_LFO = Synth.LFO_f.Value*1/Synth.Tones.Frequency(i) ; f_cut=Synth.f_cut.Value/(Synth.Tones.Fs/2); % parameters for virtualSynth func, Synth.Tones.Fs/2 = 1
                s = virtualSynth(s, a, f_LFO , f_cut, Synth.DCA_amp.Value, 1);
            case 2                                  % ripple effect, original square s = (2*(sin(a)>0)-1)*0.6;
                f_LFO = Synth.LFO_f.Value*1/Synth.Tones.Frequency(i) ; f_cut=Synth.f_cut.Value/(Synth.Tones.Fs/2); % parameters for virtualSynth func, Synth.Tones.Fs/2 = 1
                s = virtualSynth(s, a, f_LFO , f_cut, Synth.DCA_amp.Value, 2);
            case 3
                
        end
        Synth.Tones.Sample{i} = s.*Amp*Synth.DCA_amp.Value;
    end
end
%% Säädinikkunan kuvaajaa päivittävä funktio
function updatePlot()
    global Synth
    % to switch to the right figure
    %figure(4)
    plotType = Synth.PlotTypeSwitch.Value ;
            
    p = Synth.samples;

    frequency = Synth.Tones.Fs;

    t = 0:1/frequency:(length(p)/frequency-1/frequency);


    if strcmp(plotType,'Pulse')
        plot(Synth.Plot, t,p)
        %plot(app.PulsePlotUIAxes, t, p);
        %xlabel(app.PulsePlotUIAxes,'Time(s)');
    else
        lp=length(p);
        Y=fft(p);
        sig=abs(Y(1:ceil(lp/2)));
        f=linspace(0, frequency/2, ceil(lp/2));
        
        plot(Synth.Plot, f(sig>1e-4), sig(sig>1e-4));
    end     
end
%% Käyttäjän syötteeseen reagointi (hiiri, näppäimistö ja MIDI-laite)
function MousePress(ToneId)
    global Synth
    Synth.samples = Synth.Tones.Sample{ToneId};
    sound(Synth.Tones.Sample{ToneId}, Synth.Tones.Fs);
    updatePlot()
end
function KeyPress(key)
    global Synth
    id = find(ismember(Synth.Keyboard,key));
    if ~isempty(id)
        ToneId = Synth.KeyboardToneId(id);
        if (ToneId>0)
            Synth.samples = Synth.Tones.Sample{ToneId};
            sound(Synth.Tones.Sample{ToneId}, Synth.Tones.Fs);
            updatePlot()
        end
    end
end
% MIDI-syötteen lukemiseen käytettävä funktio
function updateMidi()
    global Synth
    MidiState = Synth.MidiSwitch.Value;
    
    if strcmp(MidiState,'MIDI On')
        devices = mididevinfo;
        if ~isempty(devices.input)
                miditimer = timer('Name', 'miditimer');
                miditimer.StartFcn = @initMidiTimer;
                miditimer.TimerFcn = @midiData;
                miditimer.Period = 0.005;
                miditimer.BusyMode = 'queue';
                miditimer.ExecutionMode = 'fixedSpacing';
                start(miditimer);
        else
            disp('No input midi found')
        end
    else
        timer_to_delete = timerfind('Name', 'miditimer');
        if ~isempty(timer_to_delete)
            stop(timer_to_delete)
            delete(timer_to_delete)
        end
    end
end

function initMidiTimer(src,~)
    devices = mididevinfo;
    input_device = mididevice(devices.input(1).Name);
    
    src.UserData = input_device;
end
% MIDI-syötteestä aktivoituva funktio    
function midiData(src,~)

    if hasdata(src.UserData)
        msgs = midireceive(src.UserData);
        for i = 1:length(msgs)
            if strcmp(msgs(i).Type, 'NoteOn') == true
                disp(msgs(i).Note)
                MousePress(msgs(i).Note-47)
            end
        end
    end
end



