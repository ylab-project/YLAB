function trgmat = transrg(com)

% TODO comは使わないように
ndf = com.ndf;
nj = com.nj;
njdp = com.njdp;
idnode2jf = com.idnode2jf;

repnode = com.repNode;
xr = com.xr;
yr = com.yr;

trgmat = zeros(nj*6,ndf);
for ij=1:nj
  for k=1:6
    ijk = (ij-1)*6+k;
    trgmat(ijk,idnode2jf(k,ij)) = 1;
    if any(njdp(ij)==repnode)
      switch k
        case 1
          trgmat(ijk,idnode2jf(6,ij)) = -yr(ij);
        case 2
          trgmat(ijk,idnode2jf(6,ij)) = xr(ij);
      end
    end
  end
end

return
end






