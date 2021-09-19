function isp = MillerRabinPrime(n)
    % Rabin, Michael O. (1980), "Probabilistic algorithm for testing primality",
    % Journal of Number Theory, 12 (1): 128–138
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

    % deterministic bases for Miller-Rabin up to 2^64
    % Sinclair, J. (n.d.). Deterministic variants of the Miller-Rabin
    % primality test.
    % Miller-Rabin SPRP bases records. https://miller-rabin.appspot.com/.
    if n >= 3071837692357849
        numsToTry = [2, 325, 9375, 28178, 450775, 9780504, 1795265022];
    elseif n < 1373653
        numsToTry = [2, 3];
    elseif n < 4759123141
        numsToTry = [2, 7, 61];
    elseif n < 47636622961201
        numsToTry = [2, 2570940, 211991001, 3749873356];
    else
        numsToTry = [2, 75088, 642735, 203659041, 3613982119];
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
