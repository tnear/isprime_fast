function isp = MillerRabinPrime(n)
    isp = true;
    n = n(:);

    if n <= 4
        isp = n == 2 || n == 3;
        return;
    elseif mod(n, 2) == 0
        isp = false;
        return;
    end

    % extract powers of 2
    n = uint64(n);
    d = n - 1;
    while ~bitand(d, 1) 
        d = d / 2;
    end

    % https://miller-rabin.appspot.com/
    % deterministic bases for Miller-Rabin up to 2^64
    if n < 1373653
        numsToTry = [2, 3];
    elseif n < 4759123141
        numsToTry = [2, 7, 61];
    elseif n < 47636622961201
        numsToTry = [2, 2570940, 211991001, 3749873356];
    elseif n < 3071837692357849
        numsToTry = [2, 75088, 642735, 203659041, 3613982119];
    else
        numsToTry = [2, 325, 9375, 28178, 450775, 9780504, 1795265022];
    end

    for numToTry = uint64(numsToTry)
         if ~millerRabinTest(numToTry, d, n)
             isp = false;
             return;
         end
    end
end

function isp = millerRabinTest(base, exp, n)
    % base^exp % n
    r = ModExp(base, exp, n); 

    isp = false;
    if r == 1  || r == n - 1
        isp = true;
        return;
    end

    while exp ~= n - 1
        r = ModExp(r, 2, n); 
        exp = exp + exp; 

        if r == n - 1
            isp = true;
            return;
        end
    end
end
