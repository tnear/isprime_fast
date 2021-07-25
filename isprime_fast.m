function isp = isprime_fast(N)
    isp = false(size(N));
    if isempty(N)
        return;
    end
    N = N(:);
    if ~isreal(N) || ~isnumeric(N) || any(N < 0) || any(floor(N) ~= N) || any(isinf(N))
        error(message('MATLAB:isprime:InputNotPosInt'));
    end

    % scalars
    if isscalar(N)
        isp = isScalarPrime(N);
        return;
    end

    % non-scalars
    % first, remove low primes
    isp(N == 2 | N == 3 | N == 5 | N == 7) = true;
    idx2 = find(mod(N, 2) ~= 0);
    idx3 = idx2(mod(N(idx2), 3) ~= 0);
    idx5 = idx3(mod(N(idx3), 5) ~= 0);
    idx7 = idx5(mod(N(idx5), 7) ~= 0).';
    idxToCheck = idx7;
    if isempty(idxToCheck)
        return;
    end

    maxValue = max(N(idxToCheck));
    if isInt64Flintmax(N, maxValue)
        % for numbers higher than flintmax, use Miller-Rabin
        remainingN = N(idxToCheck);
        flintmaxIdx = find(remainingN > flintmax).';
        for idx = flintmaxIdx
            isp(idxToCheck(idx)) = MillerRabinPrime(remainingN(idx));
        end

        % remove indexes already checked by MillerRabin
        idxToCheck(flintmaxIdx) = [];
        if isempty(idxToCheck)
            return;
        end
        % update maxValue which will now be less than flintmax
        maxValue = max(N(idxToCheck));
        assert(maxValue < flintmax);
    end

    if takeIsMemberPath(numel(N), maxValue)
        % get ALL primes up to max(N)
        upperBound = cast(double(maxValue), class(N));
    else
        % get primes up to sqrt(max(N))
        upperBound = cast(sqrt(double(maxValue)), class(N));
    end

    try
        p = primes(upperBound);
    catch
        % out of memory for ismember, use sqrt instead
        upperBound = cast(sqrt(double(maxValue)), class(N));
        p = primes(upperBound);
    end

    if upperBound < maxValue
        if issparse(N)
            N = full(N);
        end

        % rem() is faster with integers
        if maxValue <= 2147483647 % 2^31 - 1
            N = int32(N);
            p = int32(p);
        elseif maxValue <= 4294967295 % 2^32 - 1
            N = uint32(N);
            p = uint32(p);
        else
            N = uint64(N);
            p = uint64(p);
        end

        % check primes up to sqrt(N) using remainder
        for k = idxToCheck
            Xk = N(k);
            isp(k) = Xk>1 && all(rem(Xk, p(p<Xk)));
        end
    else
        % p contains ALL primes <= N, binary search using ismember
        isp(idxToCheck) = ismember(N(idxToCheck), p);
    end
end

function bool = isInt64Flintmax(N, maxValue)
    bool = (isa(N, 'uint64') || isa(N, 'int64')) && maxValue > flintmax;
end

function isp = isScalarPrime(N)
    if issparse(N)
        N = full(N);
    end

    % heuristics: choose best algorithm based on N
    % also convert N to integer so that mod() is faster
    if N <= 3
        isp = N == 2 || N == 3;
    elseif N < 262144 % 2^18
        isp = isSmallPrime(uint32(N));
    elseif N <= 4294967295 % 2^32 - 1
        isp = isMediumPrime(uint32(N));
    elseif N <= uint64(562949953421312) % 2^49
        isp = isMediumPrime64(uint64(N));
    else
        % large primes, > 2^49
        isp = MillerRabinPrime(N);
    end
end

function isp = isSmallPrime(N)
    if mod(N, 2) == 0
        isp = false;
    else
        % check up to sqrt(N)
        upperBound = floor(sqrt(double(N)));

        % sequence of odd numbers: [5 7 9 11 13 ...]
        seq = uint32(3):2:upperBound;

        % determine prime based on remainder
        isp = ~any(mod(N, seq) == 0);
    end
end

% create a [2 3 5 7]-prime wheel and check rem()
function isp = isMediumPrime(N)
    if any(mod(N, uint32([2, 3, 5, 7])) == 0)
        isp = false;
    else
        % check up to sqrt(N)
        upperBound = floor(sqrt(double(N)));

        % [2 3 5 7]-wheel: [1, 11, 13, 17, 19, 23, 29, 31, 37, 41, ...]
        % diff(wheel) = [10, 2, 4, 2, 4, 6, 2, 6, 4, ...]
        % create sequence of differences of elements up to sqrt(N) after
        % multiples of 2, 3, 5, and 7 are removed
        alternate = uint32([10 2 4 2 4 6 2 6 4 2 4 6 6 2 6 4 2 6 4 6 8 ...
            4 2 4 2 4 8 6 4 6 2 4 6 2 6 6 4 2 4 6 2 6 4 2 4 2 10 2]);
        timesToRepeat = floor(upperBound / 210) + 1; % cycle repeats every 2*3*5*7 = 210
        seq = cumsum(repmat(alternate, [1, timesToRepeat])) + 1;

        % determine prime based on remainder
        isp = ~any(mod(N, seq) == 0);
    end
end

% same as isMediumPrime for uint64
function isp = isMediumPrime64(N)
    if any(mod(N, uint64([2, 3, 5, 7])) == 0)
        isp = false;
    else
        % check up to sqrt(N)
        upperBound = floor(sqrt(double(N)));

        % [2 3 5 7]-wheel
        alternate = uint64([10 2 4 2 4 6 2 6 4 2 4 6 6 2 6 4 2 6 4 6 8 ...
            4 2 4 2 4 8 6 4 6 2 4 6 2 6 6 4 2 4 6 2 6 4 2 4 2 10 2]);
        timesToRepeat = floor(upperBound / 210) + 1; % cycle repeats every 2*3*5*7 = 210
        seq = cumsum(repmat(alternate, [1, timesToRepeat])) + 1;

        % determine prime based on remainder
        isp = ~any(mod(N, seq) == 0);
    end
end

function bool = takeIsMemberPath(numElements, maxValue)
    %bool = 500 * numElements > maxValue;               % 1st heuristic
    %bool = 807.6 * numElements - 125648578 > maxValue; % 2nd heuristic
    %bool = 560 * numElements - 1900000 > maxValue;     % 3rd heuristic
    if numElements < 30000                              % 4th heuristic
        bool = 275 * numElements - 50000 > maxValue;
    else
        bool = 613 * numElements - 60000000 > maxValue;
    end
end
