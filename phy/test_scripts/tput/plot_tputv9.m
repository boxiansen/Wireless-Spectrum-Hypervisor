clear all;close all;clc

bw_vector = [6 15 25 50];

slot_vector = [20];

current_tput = zeros(length(bw_vector),length(slot_vector),15);

expected_tput = zeros(length(bw_vector),length(slot_vector),15);

mcs_found = zeros(length(bw_vector),15);
for bw_idx=1:1:length(bw_vector)
    
    folderName = sprintf('./dir_tput_prb_%d/',bw_vector(bw_idx));
    
    cnt = 1;
    for mcs_idx = 0:1:28
        
        for nof_slots_idx=1:1:length(slot_vector)
            
            fileName = sprintf('%stput_prb_%d_mcs_%d_slots_%d.txt',folderName,bw_vector(bw_idx),mcs_idx,slot_vector(nof_slots_idx));
            
            ret = exist(fileName);
            
            if(ret > 0)
                
                tput_values = load(fileName);
                
                if(size(tput_values,2) >= 3)
                    
                    min = tput_values(7,1);
                    max = tput_values(7,2);
                    avg = tput_values(7,3);
                    
                    tput = (sum(tput_values(1:6,3)) - (min+max))/4;
                    
                    [tb_size] = getTBSize(getIndexFromPrB(bw_vector(bw_idx)),mcs_idx);
                    
                    full_tput = 2*((tb_size*8)/0.001);
                    
                    fprintf(1,'%d\t%d\t%d\t%f\t%f\t%f\t%f\n',bw_vector(bw_idx),mcs_idx,slot_vector(nof_slots_idx),full_tput,tput,avg,max);
                    
                    current_tput(bw_idx,nof_slots_idx,cnt) = max;
                    
                    expected_tput(bw_idx,nof_slots_idx,cnt) = full_tput;
                    
                    if(mcs_idx == 22 && bw_vector(bw_idx) == 50)
                        current_tput(bw_idx,nof_slots_idx,cnt) = max;
                    end
                    
                    if(mcs_idx == 28 && bw_vector(bw_idx) == 50) 
                        current_tput(bw_idx,nof_slots_idx,cnt) = max;
                    end
                    
                end
                
            end
            
        end
        
        if((ret > 0) & (size(tput_values,2) >= 3))
            mcs_found(bw_idx,cnt) = mcs_idx;
            cnt = cnt + 1;
        end
        
    end
    
    fprintf(1,'-----------------------------------------\n');
    
end

expected_tput_6prb = reshape(expected_tput(1,1,1:length(mcs_found)),1,16);
current_tput_6prb = reshape(current_tput(1,1,1:length(mcs_found)),1,16);

expected_tput_15prb = reshape(expected_tput(2,1,1:length(mcs_found)-1),1,15);
current_tput_15prb = reshape(current_tput(2,1,1:length(mcs_found)-1),1,15);

expected_tput_25prb = reshape(expected_tput(3,1,1:length(mcs_found)-1),1,15);
current_tput_25prb = reshape(current_tput(3,1,1:length(mcs_found)-1),1,15);

expected_tput_50prb = reshape(expected_tput(4,1,1:length(mcs_found)-1),1,15);
current_tput_50prb = reshape(current_tput(4,1,1:length(mcs_found)-1),1,15);

fdee_figure = figure('rend','painters','pos',[10 10 800 700]);
subplot(4,1,1)
plot(mcs_found(1,:),expected_tput_6prb./1e6,'k');
hold on
plot(mcs_found(1,:),current_tput_6prb(1,1:length(mcs_found))./1e6,'k*--');
set(gca,'FontSize',9)
grid on
hold off
hxlabel = xlabel('MCS');
set(hxlabel, 'FontSize', 10);
hylabel = ylabel('Throughput [Mbps]');
set(hylabel, 'FontSize', 10);
htitle = title('2 x PHY BW: 1.4 MHz - 20 TBs - 1 ms gap');
set(htitle, 'FontSize', 10);
lgd = legend('Streaming (DC: 100 %)','20 Slots (DC: 95.24 %)','Location','northwest');
lgd.FontSize = 9;
xlim([0 27])
xticks([0 2 4 6 8 10 12 14 16 18 20 22 24 25 26 27])

subplot(4,1,2)
mcs_vector = mcs_found(2,1:end-1);
plot(mcs_vector,expected_tput_15prb./1e6,'k');
hold on
plot(mcs_vector,current_tput_15prb(1,1:length(mcs_found)-1)./1e6,'k*--');
set(gca,'FontSize',9)
grid on
hold off
hxlabel = xlabel('MCS');
set(hxlabel, 'FontSize', 10);
hylabel = ylabel('Throughput [Mbps]');
set(hylabel, 'FontSize', 10);
htitle = title('2 x PHY BW: 3 MHz - 20 TBs - 1 ms gap');
set(htitle, 'FontSize', 10);
lgd = legend('Streaming (DC: 100 %)','20 Slots (DC: 95.24 %)','Location','northwest');
lgd.FontSize = 9;
xlim([0 28])
xticks([0 2 4 6 8 10 12 14 16 18 20 22 24 26 28])

subplot(4,1,3)
mcs_vector = mcs_found(3,1:end-1);
plot(mcs_vector,expected_tput_25prb./1e6,'k');
hold on;
plot(mcs_vector,current_tput_25prb(1,1:length(mcs_found)-1)./1e6,'k*--');
set(gca,'FontSize',9)
grid on
hold off
hxlabel = xlabel('MCS');
set(hxlabel, 'FontSize', 10);
hylabel = ylabel('Throughput [Mbps]');
set(hylabel, 'FontSize', 10);
htitle = title('2 x PHY BW: 5 MHz - 20 TBs - 1 ms gap');
set(htitle, 'FontSize', 10);
lgd = legend('Streaming (DC: 100 %)','20 Slots (DC: 95.24 %)','Location','northwest');
lgd.FontSize = 9;
xlim([0 28])
xticks([0 2 4 6 8 10 12 14 16 18 20 22 24 26 28])

subplot(4,1,4)
mcs_vector = mcs_found(4,1:end-1);
plot(mcs_vector,expected_tput_50prb./1e6,'k');
hold on;
plot(mcs_vector,current_tput_50prb(1,1:length(mcs_found)-1)./1e6,'k*--');
set(gca,'FontSize',9)
grid on
hold off
hxlabel = xlabel('MCS');
set(hxlabel, 'FontSize', 10);
hylabel = ylabel('Throughput [Mbps]');
set(hylabel, 'FontSize', 10);
htitle = title('2 x PHY BW: 10 MHz - 20 TBs - 1 ms gap');
set(htitle, 'FontSize', 10);
lgd = legend('Streaming (DC: 100 %)','20 Slots (DC: 95.24 %)','Location','northwest');
lgd.FontSize = 9;
xlim([0 28])
xticks([0 2 4 6 8 10 12 14 16 18 20 22 24 26 28])
