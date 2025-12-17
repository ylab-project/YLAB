function [defrect, stress, form, fr, rps, wid_gc, standardGap_gc] = separateC(c, conVar)
        % ----- common -----
        ng = conVar.ng;
        nc = conVar.nc;
        nlc = conVar.nlc;
        nsj = conVar.nsj;
        nfl = conVar.nfl;
        nvg = conVar.nvg;
        nvc = conVar.nvc;
        nj = conVar.nj;
        
        stressn = ng*nlc * 3 + nc*nlc * 2 + ng*nlc * 2 + nc*nlc * 2;
        formn = ng;
        widethickn = 2*nvg;
        widecn = nvc;
        widegln = nvg;
        rpsn = (nj - 2*nsj)*2;
        defrectn = nfl*(nlc-1);
        frn = ng;
        stress = c(1:stressn);
        form = c(stressn+1:stressn+formn);
        %梁フランジの下限値あり
        widC = c(stressn+formn+1:stressn+formn+widethickn+widecn+widegln);
        %梁フランジの下限値なし
        wid_gc = c(stressn+formn+1:stressn+formn+widethickn+widecn);
        fr = c(stressn+formn+length(widC)+1:stressn+formn+length(widC)+frn);
        defrect = c(stressn+formn+length(widC)+frn+1:stressn+formn+length(widC)+frn+defrectn);
        rps = c(stressn+formn+length(widC)+frn+defrectn+1:stressn+formn+length(widC)+frn+defrectn+rpsn);
        standardGap_gc = c(stressn+formn+length(widC)+frn+defrectn+rpsn+1 : stressn+formn+length(widC)+frn+defrectn+rpsn+nvg+nvc);
        defrect = defrect(1:2*nfl);
    end