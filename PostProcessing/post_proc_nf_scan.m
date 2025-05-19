%% Logistics
clear all
c=physconst('LightSpeed');

%% Parameters
% extraction file
fname='./Data/NearFieldRawData_Eravant_051525.mat';
% extraction frequency
f_exe_GHz=12;
% windowing parameters
perform_time_gate=true;
r_st=0.3; r_en=1.3; r_sigma=0.02;
% Interpolation
N1q=40; Nq=2*N1q+1;
% Waveguide Probe Size
a_WG=22.86e-3; b_WG=10.16e-3;
% Radiation Pattern Cuts
phi_cuts_deg=0:45:90;

%% Extraction - NF Scanner
load(fname);
Xe=paramsTable.("X position").*1e-3;
Ye=paramsTable.("Y position").*1e-3;
Np=length(Xe); N1=sqrt(Np); N1p=(N1-1)/2;
dx=Xe(2)-Xe(1);
xv=dx.*(-N1p:N1p);
[Xm,Ym]=ndgrid(xv,xv); X=Xm(:); Y=Ym(:);
SPDataMat=paramsTable.("S parameters");
f=SPDataMat(1).Frequencies; Nf=length(f); fg=f./1e9;
fc=mean(f);
[~,f_exe_idx]=min(abs(fg-f_exe_GHz));
fge=fg(f_exe_idx);
lame=c/fge/1e9;

%% Resort due to Raster Scan
s=zeros(Np,Nf);
for row=1:N1
    for col=1:N1
        extraction_idx=(row-1)*N1+mod(row,2)*(N1+1)+(-1)^(row)*col;
        sorted_idx=(row-1)*N1+col;
        SPD=SPDataMat(extraction_idx).Parameters;
        s(sorted_idx,:)=squeeze(SPD(2,1,:));
    end
end

%% Compute Windowed Pattern
sw=zeros(Np,Nf); df=f(2)-f(1);
t_ifft=linspace(0,1/df,Nf); r_ifft=c.*t_ifft;
if perform_time_gate
    window_td=window_sigmoid(r_ifft,r_st,r_en,r_sigma);
else
    window_td=ones(size(r_ifft));
end
for spatial_idx=1:Np
    s_tmp=squeeze(s(spatial_idx,:));
    s_ifft=ifft(ifftshift(s_tmp));
    sw(spatial_idx,:)=fftshift(fft(s_ifft.*window_td));    
end

%% Convert Center Signal to Time Domain
gating_idx=round(Np/2);
s_mid=squeeze(s(gating_idx,:));
a_ifft=ifft(ifftshift(s_mid));
[~,peak_idx]=max(abs(a_ifft));
r_peak=r_ifft(peak_idx);
fo=f-fc; r_dift=r_peak+1.5.*linspace(-1,1,801); t_dift=r_dift./c;
[Fom,Tm]=ndgrid(fo,t_dift);
[freq_idx,~]=ndgrid(1:Nf,t_dift);
a=sum(s_mid(freq_idx).*exp(1j.*2.*pi.*Fom.*Tm),1);
a_max=max(abs(a)); a=a./a_max;
a_ifft_plt=a_ifft./a_max;

%% Extract Windowed Response at Frequency of Interest over Space
sxy=zeros(N1,N1); sxy(:)=sw(:,f_exe_idx);

%% Interpolation
xqv=linspace(xv(1),xv(end),Nq); dxq=xqv(2)-xqv(1);
[Xq,Yq]=ndgrid(xqv,xqv);
mag2_q=(interp2(Xm.',Ym.',abs(sxy).^2.',Xq.',Yq.','cubic')).';
real_q=(interp2(Xm.',Ym.',cos(angle(sxy)).',Xq.',Yq.','cubic')).';
imag_q=(interp2(Xm.',Ym.',sin(angle(sxy)).',Xq.',Yq.','cubic')).';
phase_q=atan2(imag_q,real_q);
sxyq=sqrt(mag2_q).*exp(1j.*phase_q);


%% Convert to Spatial Frequency Domain (With Spatial Zero Padding)
Ns=Nq; nu_max=1/2/dx; % Inherently assumes zero padding
nuv=linspace(-nu_max,nu_max,Ns);
[Nux,Nuy]=ndgrid(nuv,nuv);
Vk=zeros(Ns,Ns);
Vk(:)=sum(sxyq(:).*exp(1j.*2.*pi.*(Nux(:).'.*Xq(:)+Nuy(:).'.*Yq(:))));
% for nx=1:Ns
%     for ny=1:Ns
%         Vk(nx,ny)=sum(sxyq(:).*exp(1j.*2.*pi.*(Nux(nx,ny).*Xq(:)+Nuy(nx,ny).*Yq(:))));
%     end
% end

%% Perform Probe Compensation
nu0=1/lame;
Nuz=sqrt(nu0.^2-Nux.^2-Nuy.^2);
F_probe=(sinc(Nux.*a_WG-0.5)+sinc(Nux.*a_WG+0.5)).*sinc(Nuy.*b_WG);
Eyk_probe_comp=Vk./(Nuz./nu0.*F_probe.*(1+Nuy.^2./Nuz.^2));
Nu_rho=sqrt(Nux(:).^2+Nuy(:).^2);
Eyk=Eyk_probe_comp; Eyk(Nu_rho./nu0>1)=0;
Eyk=Eyk./max(abs(Eyk(:)));

%% Compute Far-Field Radiation Pattern along cuts
Eff=Nuz./nu0.*Eyk; Eff=Eff./max(abs(Eff(:)));
phi_c=phi_cuts_deg.*pi./180;
th_c=linspace(-pi/2,pi/2,201).';
kxn_c=sin(th_c).*cos(phi_c);
kyn_c=sin(th_c).*sin(phi_c);
Eff_c=interp2(Nux.'./nu0,Nuy.'./nu0,Eff.',kxn_c,kyn_c);


%% Convert Back to Spatial Domain (With Spectral Zero Padding)
Nr=Nq;
xrv=linspace(xv(1),xv(end),Nr);
[Xr,Yr]=ndgrid(xrv,xrv);
Eyr_idft=zeros(Nr,Nr);
Eyr_idft(:)=sum(Eyk(:).*exp(-1j.*2.*pi.*(Nux(:).*Xr(:).'+Nuy(:).*Yr(:).')));
Eyr=Eyr_idft./max(abs(Eyr_idft(:)));
% for nx=1:Nr
%     for ny=1:Nr
%         Eyr(nx,ny)=sum(Eyk_normalized(:).*exp(-1j.*2.*pi.*(Nux(:).*Xr(nx,ny)+Nuy(:).*Yr(nx,ny))));
%     end
% end

%% Window Parameters
window_dift=window_sigmoid(r_dift,r_st,r_en,r_sigma);
windowed_signal=a_ifft.*window_td;
s_window=fftshift(fft(windowed_signal));

%% Plotting Logistics (restart matlab to go back to default settings)
fig_cnt=0;
set(groot,'defaultTextInterpreter','latex')
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',16)
set(groot,'defaultLineLineWidth', 1.2);
format compact

%% Plotting - View Center Point in Frequency and Time Domain
fig_cnt=fig_cnt+1; figure(fig_cnt); clf(fig_cnt); hold on

% Frequency
subplot(2,1,1); hold on
plot(fg,20.*log10(abs(s_mid)),'r')
plot(fg,20.*log10(abs(s_window)),'b-.')
legend('Extracted','Time Gated')
grid on
xlabel('Frequency (GHz)');
ylabel('$S_{21}$ (dB)')

% Time
subplot(2,1,2); hold on
plot(r_ifft,abs(a_ifft_plt).*Nf,'r-o')
plot(r_dift,abs(a),'b')
plot(r_dift,abs(a.*window_dift),'c--')
plot(r_dift,window_dift,'k')
grid on
xlabel('(m)')
xlim(r_dift([1,end]))
% xlim([0,2])
leg=legend('Ungated Raw','Ungated Smooth','Gated Smooth','Window');
set(leg,'Location','northwest')

%% Plotting Spatial / Spectral Phase / Amplitude
fig_cnt=fig_cnt+1; figure(fig_cnt); clf(fig_cnt); hold on

% Spatial Magnitude
ax1=subplot(2,2,1);
imagesc(xrv.*100,xrv.*100,20.*log10(abs(Eyr.')))
colormap(ax1,'parula');
clim([-20,0]); xlim(xrv([1,end]).*100); ylim(xrv([1,end]).*100);
title('$|E_y (\vec{r})|$ (dB)')
axis square
xlabel('$x$ (cm)');
ylabel('$y$ (cm)');
colorbar

% Spatial Phase
ax2=subplot(2,2,3);
imagesc(xrv.*100,xrv.*100,angle(Eyr.').*180./pi)
colormap(ax2,'hsv');
clim([-180,180]); xlim(xrv([1,end]).*100); ylim(xrv([1,end]).*100);
title('$\angle E_y (\vec{r})$ (deg)')
axis square
xlabel('$x$ (cm)');
ylabel('$y$ (cm)');
cb=colorbar;
cb.Ticks=-180:90:180;

% Spectral Magnitude
ax3=subplot(2,2,2);
imagesc(nuv./nu0,nuv./nu0,20.*log10(abs(Eyk.')))
colormap(ax3,'parula')
clim([-20,0]); xlim([-1,1]); ylim([-1,1]);
rectangle('Position',[-1,-1,2,2],'Curvature',[1,1],'EdgeColor','w')
title('$|\tilde{E}_y (\vec{k})|$ (dB)')
axis square
xlabel('$k_x / k_0$');
ylabel('$k_y / k_0$');
colorbar

% Spectral Phase
ax4=subplot(2,2,4);
imagesc(nuv./nu0,nuv./nu0,angle(Eyk.').*180./pi)
colormap(ax4,'hsv')
clim([-180,180]); xlim([-1,1]); ylim([-1,1]);
rectangle('Position',[-1,-1,2,2],'Curvature',[1,1],'EdgeColor','k')
title('$\angle \tilde{E}_y (\vec{k})$ (deg)')
axis square
xlabel('$k_x / k_0$');
ylabel('$k_y / k_0$');
cb=colorbar;
cb.Ticks=-180:90:180;

%% Plotting - Sanity Check
% fig_cnt=fig_cnt+1; figure(fig_cnt); clf(fig_cnt); hold on
% imagesc(20.*log10(abs(Eyr.')))
% colormap('parula');
% clim([-20,0]);
% title('$|E_y (\vec{r})|$ (dB)')
% set(gca,'YDir','Normal')
% axis square
% colorbar
% exportgraphics(gca,'Er_mag.emf','BackgroundColor','none')


%% Plotting - Spatial Field Cuts
fig_cnt=fig_cnt+1; figure(fig_cnt); clf(fig_cnt); hold on
Z_cuts=-0.2:0.05:0.4;
xylim=abs(Z_cuts(end)-Z_cuts(1))/4;
rot_cut_deg=0.*180./pi; mindB=-24; swapXandZ=true; plot_coarse_cuts=true;
f_plot_spatial_cuts(N1q,dx,N1q,dx,Z_cuts,xylim,0.*Eyk(:),Eyk(:),2*pi*nu0,rot_cut_deg,mindB,0,swapXandZ,plot_coarse_cuts,fig_cnt)
xlim(Z_cuts([1,end]))
ylim([-1,1].*xylim);
zlim([-1,1].*xylim);
axis equal
view([140 20])
title('Normalized Near Field Power (dB)')
% set(gcf,'Position',[521 299 452 260])
% set(gcf,'Position',[523 308 579 313]);
print(gcf,'NearFieldProfile','-dpng','-r600')


%% Plotting - Baloon Pattern
fig_cnt=fig_cnt+1; figure(fig_cnt); clf(fig_cnt); hold on
mindB=-40;
f_plot_baloon_pattern(0.*Eyk,Eyk,Nux./nu0,Nuy./nu0,mindB,fig_cnt)

%% Plotting - Radiation Cuts
fig_cnt=fig_cnt+1; figure(fig_cnt); clf(fig_cnt); hold on
for nc=1:length(phi_c)
    plot(th_c.*180./pi,20.*log10(abs(Eff_c(:,nc))))
    grid on
    xlabel('Elevation Angle (deg)')
    ylabel('Normalized Radiation (dB)')
    ylim([-40,0])
    xlim([-1,1].*90)
    xticks(-90:30:90)
    legend_str{nc}=sprintf('$\\phi = %0.1f ^\\circ$',phi_c(nc)*180/pi);
end
legend(legend_str)

%% Functions - Window
function f_wind=window_sigmoid(r,r_st,r_en,r_sigma)
    f_wind=(1+exp(-(r-r_st)./r_sigma)).^-1-(1+exp(-(r-r_en)./r_sigma)).^-1;
end

%% Function - Baloon Plot
function f_plot_baloon_pattern(Exk,Eyk,kxn,kyn,mindB,fig_num)
    krn=sqrt(kxn.^2+kyn.^2); kzn=sqrt(1-krn).^2.*(krn<1);
    E_mag_k=sqrt(abs(Exk).^2+abs(Eyk).^2);
    Field_Pattern=kzn.*E_mag_k;
    FFb=abs(Field_Pattern./max(max(abs(Field_Pattern)))).';
    Rb=max((20.*log10(FFb)-mindB)./abs(mindB),0);
    Xb=kxn.'.*Rb; Yb=kyn.'.*Rb; Zb=kzn.'.*Rb;
    figure(fig_num); clf(fig_num); hold on;
    jet_map=colormap("jet");
    baloon_scaled_colordata=ceil(Rb*length(jet_map).*.99);
    srf=surf(Xb,Yb,Zb,'LineStyle','none');
    srf.CData=baloon_scaled_colordata;
    colormap jet
    cb=colorbar; cbv=0:0.2:1;
    cb.Ticks=(length(jet_map)-2).*cbv;
    cb.TickLabels=num2str(mindB.*(1-cbv.'));
    cb.Label.String='P_{rad}';
    set(gca,'YDir','normal')
    grid off
    ax=gca; ax.XTickLabel=[]; ax.YTickLabel=[]; ax.ZTickLabel=[];
    ax.Color='none';
    ax.XAxis.Visible='off'; ax.YAxis.Visible='off'; ax.ZAxis.Visible='off';
    view([45,30]); axis equal; rotate3d on
end

%% Function Spatial Cuts Plotting
function f_plot_spatial_cuts(Mp,dx,Np,dy,Z_cuts,xylim,E_x_k,E_y_k,k0,rot_cut_deg,mindB,maxdB,swapXandZ,plot_coarse_cuts,fig_num)
    % Post Proc Input
    M=2*Mp+1; N=2*Np+1; Xtot=M*dx; Ytot=N*dy;
    [P,Q]=ndgrid((-Mp:Mp),(-Np:Np)); dkx=2*pi/Xtot; dky=2*pi/Ytot; KX=P.*dkx; KY=Q.*dky;
    KT=sqrt(KX.^2+KY.^2);
    KZ=-1j.*sqrt(KT.^2-k0.^2);
    % Spatial Grid
    zf=linspace(Z_cuts(1),Z_cuts(end),201);
    if plot_coarse_cuts
        zc=Z_cuts;
    else
        zc=linspace(Z_cuts(1),Z_cuts(end),51);
    end
    cr=cosd(rot_cut_deg); sr=sind(rot_cut_deg);
    xf=linspace(-xylim,xylim,501).*Mp.*dx;
    yf=linspace(-xylim,xylim,501).*Np.*dy;
    % Compute PW Spectrum for all Z
    E_x_k_allZ=E_x_k(:).*exp(-1j.*KZ(:).*zf);
    E_y_k_allZ=E_y_k(:).*exp(-1j.*KZ(:).*zf);
    E_x_k_coarseZ=E_x_k(:).*exp(-1j.*KZ(:).*zc);
    E_y_k_coarseZ=E_y_k(:).*exp(-1j.*KZ(:).*zc);
    % XZ Plane
    [Xpxz,Zxz]=meshgrid(xf,zf);
    E_x_xz=exp(-1j.*(xf.'.*(cr.*KX(:).'+sr.*KY(:).')))*E_x_k_allZ;
    E_y_xz=exp(-1j.*(xf.'.*(cr.*KX(:).'+sr.*KY(:).')))*E_y_k_allZ;
    E_mag_xz=sqrt(abs(E_x_xz).^2+abs(E_y_xz).^2);
    % YZ Plane
    [Yyz,Zyz]=meshgrid(xf,zf);
    E_x_yz=exp(-1j.*(yf.'.*(cr.*KY(:).'-sr.*KX(:).')))*E_x_k_allZ;
    E_y_yz=exp(-1j.*(yf.'.*(cr.*KY(:).'-sr.*KX(:).')))*E_y_k_allZ;
    E_mag_yz=sqrt(abs(E_x_yz).^2+abs(E_y_yz).^2);
    % XY Cuts
    [Xxy,Yxy]=meshgrid(xf,yf);
    E_x_xy=zeros(M,N,length(zc));
    E_y_xy=zeros(M,N,length(zc));
    for zci=1:length(zc)
        E_x_xy(:,:,zci)=f_spectral2space(reshape(E_x_k_coarseZ(:,zci),[M,N]));   
        E_y_xy(:,:,zci)=f_spectral2space(reshape(E_y_k_coarseZ(:,zci),[M,N]));   
    end
    E_mag_xy=sqrt(abs(E_x_xy).^2+abs(E_y_xy).^2);
    % Convert to RGB Images
    maxval=max([E_mag_xz(:);E_mag_yz(:);E_mag_xy(:)]);
    E_mag_xz_dB=max(20.*log10(E_mag_xz./maxval),mindB);
    E_mag_yz_dB=max(20.*log10(E_mag_yz./maxval),mindB);
    E_mag_xy_dB=max(20.*log10(E_mag_xy./maxval),mindB);
    [rgb_image_XZ,Scl_Im_XZ]=cmap_scaled_rgb('jet',E_mag_xz_dB.',mindB,maxdB);
    [rgb_image_YZ,Scl_Im_YZ]=cmap_scaled_rgb('jet',E_mag_yz_dB.',mindB,maxdB);
    rgb_image_XY=zeros(M,N,3,length(zc));
    Scl_Im_XY=zeros(M,N,length(zc));
    for zci=1:length(zc)
        [rgb_tmp,scl_tmp]=cmap_scaled_rgb('jet',E_mag_xy_dB(:,:,zci).',mindB,maxdB);
        rgb_image_XY(:,:,:,zci)=rgb_tmp; Scl_Im_XY(:,:,zci)=scl_tmp;
    end
    % Build Plot
    figure(fig_num); clf(fig_num)
    hold on
    if plot_coarse_cuts
        if swapXandZ
            wxz=warp(Zxz,cr.*Xpxz,sr.*Xpxz,rgb_image_XZ);
        else
            wxz=warp(cr.*Xpxz,sr.*Xpxz,Zxz,rgb_image_XZ);
        end
        wxz.FaceAlpha='texturemap'; wxz.AlphaDataMapping='none';
        wxz.AlphaData=(Scl_Im_XZ).^0.25;
        if swapXandZ
            wyz=warp(Zyz,-sr.*Yyz,cr.*Yyz,rgb_image_YZ);
        else
            wyz=warp(-sr.*Yyz,cr.*Yyz,Zyz,rgb_image_YZ);
        end
        wyz.FaceAlpha='texturemap'; wyz.AlphaDataMapping='none';
        wyz.AlphaData=(Scl_Im_YZ).^0.25;
    end
    for zci=1:length(zc)
        if swapXandZ
            wxy=warp(zc(zci)+0.*Xxy,Xxy,Yxy,rgb_image_XY(:,:,:,zci));
        else
            wxy=warp(Xxy,Yxy,zc(zci)+0.*Xxy,rgb_image_XY(:,:,:,zci));
        end
        wxy.FaceAlpha='texturemap'; wxy.AlphaDataMapping='none';
        wxy.AlphaData=(Scl_Im_XY(:,:,zci)).^0.25;
    end
    xlabel('z (m)'); ylabel('x (m)'); zlabel('y (m)');
    grid on
    colormap jet
    cbar=colorbar;
    cbar.Ticks=linspace(0,1,5);
    cbar.TickLabels=split(num2str(round(linspace(mindB,maxdB,5))));
%     cbar.Title.String='(dB)';

end

%% Function - 2D Fourier Transform
function E_r=f_spectral2space(E_k)
    E_k_shift=fftshift(fftshift(E_k,2),1);
    E_r_shift=fft2(E_k_shift);
    E_r=fftshift(fftshift(E_r_shift,2),1);
end

%% Function - Building Scaled Colormap
function [rgb_image,scaled_image]=cmap_scaled_rgb(map_str,Matrix_2D,minval,maxval)
    map = colormap(map_str);
    ncol = size(map,1);
    scaled_image=(Matrix_2D-minval)/(maxval-minval);
    indexed_image = round(1+(ncol-1)*scaled_image);
    rgb_image = ind2rgb(indexed_image,map);
end


