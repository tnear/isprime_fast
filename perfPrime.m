function [t1, t2, t3] = perfPrime(numBits)
    t1 = [];
    t2 = [];
    t3 = [];
    for idx = 1:100
        [x, y, z] = getPerf(numBits);
        t1 = [t1, x]; %#ok<AGROW>
        t2 = [t2, y]; %#ok<AGROW>
        t3 = [t3, z]; %#ok<AGROW>
    end
    t1 = mean(t1);
    t2 = mean(t2);
    t3 = mean(t3);
end

function [t1, t2, t3] = getPerf(numBits)
    low = 2^(numBits - 1);
    high = 2^numBits - 1;
    if numBits >= 53
        num = 0;
        while mod(num, 2) == 0
            % randi only supports < 2^53
            % instead take high number and subtract largest randi range
            % this skews data toward high side of numBits, but it sufficient
            % for basic performance testing
            num = uint64(2)^numBits - randi(2^53 - 1);
        end
    else
        num = 0;
        while mod(num, 2) == 0
            num = randi([low, high]);
        end
    end

    if num < 2^47
        t1 = timeit(@() isprime(num));
    else
        % built-in becomes a little slow for timeit
        tic;
        isprime(num);
        t1 = toc;
    end
    t2 = timeit(@() isprime_fast(num));
    sNum = sym(num);
    t3 = timeit(@() isprime(sNum));
end

function int32Matrix
    range = randi(intmax('int32'), [1000, 1000], 'int32');
    tic, isprime(range); toc
    % Elapsed time is 17.686067 seconds.
    tic, isprime_fast(range); toc
    % Elapsed time is 3.927214 seconds.

    sRange = sym(range);
    tic, isprime(sRange); toc
end

function oneHundredLargestPrimes
    % 100 largest primes
    prime = zeros(1, 100, 'uint64');
    prime(1) = prevprime(uint64(inf));
    for x = 2:100
        prime(x) = prevprime(prime(x-1)) - 1;
    end


    tic, isprime(prime); toc
    % Elapsed time is 206.562121 seconds.

    timeit(@() isprime_fast(prime))
    % 0.1442

    sPrime = sym(prime);
    timeit(@() isprime_fast(sPrime))
    % 0.0284
end

function oneHundredPseudoPrimesBelowFlintmax
    % flintmax = 2^53
    found = [];
    for x = 1:2:1000
        num = 2^53 - x;
        f = factor(num);
        if numel(f) == 2 && f(1) > 1000000
            % find pseudoprimes with reasonably high (> 1M) factors
            disp(int64(num));
            found = [found, num];
        end
    end
end
