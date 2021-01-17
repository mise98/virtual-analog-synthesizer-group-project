% Lisää LFO-efektin syötesignaaliin osc
function s = virtualSynth(osc, a, f_LFO , f_cut, A, LFO_type)

    DCF = zeros(1, length(a));
    %% LFO-efektin valinta
    switch LFO_type
        case 1 % tremolo
            LFO = sin(f_LFO*a);
            [b,a] = butter(4, f_cut, 'low');
            DCF = filter(b,a,osc);
            s = DCF.*(1 + 0.258925 .* LFO);
        case 2 % ripple
            
            LFO = (1 + 0.2*sin(f_LFO*a));
            i = 1;
            windowsize = 300;
            while i<=length(a)

                cutfreq = LFO(1,i)*f_cut;
                if i + windowsize > length(a)
                    nleft = length(a) - i;
                    
                    [b,a1] = butter(4, cutfreq, 'low');
                    %DCF(1, i:(i+(nleft-1))) = filter(b,a1,osc(i:(i+(nleft-1))));
                    window = hamming(nleft);
                    y = window'.*osc(i:(i+(nleft-1)));
                    DCF(1, i:(i+(nleft-1))) = filter(b,a1,y);
                else
                
                    
                    [b,a1] = butter(4, cutfreq, 'low');
                    %DCF(1, i:(i+(windowsize-1))) = filter(b,a1,osc(i:(i+(windowsize-1))));
                    window = hamming(windowsize);
                    y = window'.*osc(i:(i+(windowsize-1)));
                    DCF(1, i:(i+(windowsize-1))) = filter(b,a1,y);
                end
                
                i = i + windowsize;
                %disp(cutfreq)
            end
            %DCA = A*DCF;
            % return
            s = DCF;
            
    end
end
