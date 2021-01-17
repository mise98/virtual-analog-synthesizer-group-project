% eksponentiaalinen nousu ja lasku start ja stop välille n:llä väliarvolla
function v = expdecay(start, stop, n)
     v = start*exp(-(linspace(0, -log(stop/start), n)));
end