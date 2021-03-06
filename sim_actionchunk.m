function simdata = sim_actionchunk(agent)
%% 
% action chunking
rng(0)

nS = 4;  % # state features
nA = 5;   % # actions
theta = zeros(nS,nA);                 % policy parameters (13 state-features, 4 actions)
V = zeros(nS,1);                      % state value weights
p = ones(1,nA)/nA;                    % marginal action probabilities

c = [3 2 1];     % hidden "chunk"
trials = 100;    % total trials
randtrials = trials - length(c)*15; % randomly occuring trials
state = [1 c 4 2 c 4 3 4 1 c 4 3 2 c 1 4 3 4 c 4 4 2 4 c 4 3 4 1 c 4 4 2 c 4 3 1 4 c 2 c 2 1 4 c 4 c 4 c 4 c 4 c 4 3 4 c 4 c 4 c 4 c];
state = repmat(state,1,10); % 1000 trials
R = [1 0 0 0 0;
    0 1 0 0 0;
    0 0 1 0 1;
    0 0 0 1 0];

for i = 1:4
    sum(state == i);
end
%% 

rt = 0;
chunk = 0; % indicates whether it is in a chunk
for t = 1:length(state)
    s = state(t);  % sample start location
    
    % policy
    if chunk == 0  % not in a chunk, sample action and get reward
        d = agent.beta*theta(s,:) + log(p);
        logpolicy = d - logsumexp(d);
        policy = exp(logpolicy);    % softmax
        a = fastrandsample(policy);   % sample action
        
        % reward
        r = R(s,a);
        rt = rt+1; % reaction time
        
    else % still in chunk
        a = 5;
        % reward
        r = R(s,c(clen));
        rt = rt+0.3; % reaction time
        s = 3;
    end
    
    if a == 5 && chunk == 0 % if you just start a chunk
        chunk = 1; % turn the chunk on and off
        clen = 1;
        rt = rt+0.3;
    end
    
    cost = logpolicy(a) - log(p(a));    % policy complexity cost
    
    if chunk == 1
        if clen > 1 % if action is tere
            cost = 0; % no cost if executing chunk
        end
        clen = clen + 1;
        
        if clen > length(c)
            chunk = 0;  % turn chunk off when action sequence is over
            clen = 0;
        end
        
    end
    
    % learning updates
    rpe = agent.beta*r - cost - V(s);                      % reward prediction error
    g = agent.beta*(1 - policy(a));                        % policy gradient
    theta(s,a) = theta(s,a) + (agent.lrate_theta)*rpe*g;   % policy parameter update
    V(s) = V(s) + agent.lrate_V*rpe;
    
    p = p + agent.lrate_p*(policy - p); p = p./nansum(p);        % marginal update
    simdata.action(t) = a;
    simdata.reward(t) = r;
    simdata.state(t) = s;
    simdata.cost(t) = cost;
    
end

simdata.rt = rt/length(state);
simdata.V = V;
simdata.theta = theta;
simdata.pa = p;

for i = 1:nS
    d = agent.beta*theta(i,:) + log(p);
    logpolicy = d - logsumexp(d,2);
    policy = exp(logpolicy);    % softmax
    simdata.pas(i,:) = policy;
end

simdata.chooseC1 = sum(simdata.state == 3 & simdata.action==5)/sum(simdata.state == 3);
simdata.chooseA3 = sum(simdata.state == 3 & simdata.action==3)/sum(simdata.state == 3);

simdata.KL = nansum(simdata.pas.*log(simdata.pas./simdata.pa),2);


if agent.test == 1
    
    state = state(randperm(length(state))); % shuffle states
    
    rt = 0;
    chunk = 0;
    for t = 1:length(state)
        s = state(t);  % sample start location
        
        % policy
        if chunk == 0
            d = agent.beta*theta(s,:) + log(p);
            logpolicy = d - logsumexp(d);
            policy = exp(logpolicy);    % softmax
            a = fastrandsample(policy);   % sample action
            
            % reward
            r = R(s,a);
            rt = rt+1; % reaction time
            
        else % still in chunk
            a = 5;
            % reward
            r = R(s,c(clen));
            rt = rt+0.3; % reaction time
            s = 3;
        end
        
        if a == 5 && chunk == 0 % if you just start a chunk
            chunk = 1; % turn the chunk on and off
            clen = 1;
            rt = rt+0.3;
        end
        
        
        cost = logpolicy(a) - log(p(a));    % policy complexity cost
        
        if chunk == 1
            if clen > 1 % if action is tere
                cost = 0; % no cost if executing chunk
            end
            clen = clen + 1;
            
            if clen > length(c)
                chunk = 0;  % turn chunk off when action sequence is over
                clen = 0;
            end
            
        end
        
        
        % learning updates
        rpe = agent.beta*r - cost - V(s);                      % reward prediction error
        g = agent.beta*(1 - policy(a));                        % policy gradient
        theta(s,a) = theta(s,a) + (agent.lrate_theta)*rpe*g;   % policy parameter update
        V(s) = V(s) + agent.lrate_V*rpe;
        
        p = p + agent.lrate_p*(policy - p); p = p./nansum(p);        % marginal update
        simdata.test.action(t) = a;
        simdata.test.reward(t) = r;
        simdata.test.state(t) = s;
        simdata.test.cost(t) = cost;
        
    end % state
    
    simdata.test.slips = sum(simdata.test.state == 3 & simdata.test.action==5)/sum(simdata.test.state == 3);
    simdata.test.chooseA3 = sum(simdata.test.state == 3 & simdata.test.action==3)/sum(simdata.test.state == 3);

    simdata.test.rt = rt/length(state);
end % agent test


end