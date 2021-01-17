function EG = ADSR(T, fs, aT, dT, sT, rT)
    % defaulttina kaikki vaiheet ovat saman pituisia (eli 25% kokonaiskestosta T)   
    if (nargin < 3)
        aT = 0.25;
        dT = 0.25;
        sT = 0.25;
        rT = 0.25;
    end
    T_attack = T*aT; T_decay = T * dT; T_sustain = T * sT; T_release = T * rT; 
    
    attack = expdecay(0.01,1, floor(T_attack*fs));
    decay = expdecay(attack(end), attack(end)/2, floor(T_decay * fs)); %exp
    sustain = decay(end)*ones(1, floor(T_sustain*fs));
    release = expdecay(sustain(end), 0.01, floor(T_release*fs)); %exp
    
    EG = [attack decay sustain release];
    if length(EG) < fs*T
        EG = [EG zeros(1, floor(fs*T - length(EG)))];
    end
end