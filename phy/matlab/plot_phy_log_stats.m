clear all;close all;clc

BATCH_ID=17772;

folder = sprintf('/home/zz4fap/Downloads/link_level_check/SC5/PHY/RESERVATION-%d-logs/',BATCH_ID);

delete_str=sprintf('rm %s*.png',folder);
system(delete_str);

sub_folders = dir(folder);

filename = 'phy_stdout.txt';

%% Process file for received ACK message.
string1_to_look_for = ' - [TX STATS]: #';
string2_to_look_for = ' - Set TX gain to: ';
string3_to_look_for = ' - [RX STATS]: # ';
string4_to_look_for = ' - [RX STATS]: Number of wrong decodings: ';

figure_counter = 0;
for k=3:1:length(sub_folders)
    
    sub_folder = sub_folders(k).name;
    
    % Open file.
    full_path_to_file = sprintf('%s/%s/%s',folder,sub_folder,filename);
    fid = fopen(full_path_to_file);
    
    % TX and RX Message stats structure.
    tx_stats_struct = [];
    rx_stats_struct = [];
    wrong_rx_stats_struct = [];
    
    tline = fgetl(fid);
    first_timestamp = -1;
    while ischar(tline)
                
        %% ------------------------------------------------------------------
        % Find line with first timestamp report.
        ret = strfind(tline,'[PHY RX INFO]: [');
        if(~isempty(ret) && first_timestamp == -1)     
            first_timestamp = str2double(tline(28:29))*3600 + str2double(tline(31:32))*60 + str2double(tline(34:35)) + str2double(tline(36:42));            
        end
        
        %% ------------------------------------------------------------------
        % Find line with TX stats report.
        ret = strfind(tline,string1_to_look_for);
        if(~isempty(ret))
            %fprintf(1,'%s\n',tline);
            % *** Get log timestamp. ***
            tx_stats_timestamp = str2double(tline(28:29))*3600 + str2double(tline(31:32))*60 + str2double(tline(34:35)) + str2double(tline(36:42));
            
            % *** Retrieve channel from log. ***
            end_of_desired_str = find(tline==':',6);
            aux_str = tline(end_of_desired_str(6)+2:end);
            end_of_desired_str = find(aux_str=='-',1);
            channel_string = aux_str(1:end_of_desired_str-2);
            channel = str2num(['int64(' channel_string ')']);
            %fprintf(1,'Channel: %d\n',channel);
            
            % *** Add channel to struct. ***
            if(isempty(tx_stats_struct))
                tx_stats.channel = channel;
                tx_stats.number_of_slots = [];
                tx_stats.mcs = [];
                tx_stats.coding_time = [];
                tx_stats.tx_gain = [];
                tx_stats.timestamp_diff = [];
                tx_stats_struct = [tx_stats_struct, tx_stats];
                index = 1;
            else
                number_ot_tx_stats = length(tx_stats_struct);
                index = -1;
                for i=1:1:number_ot_tx_stats
                    tx_stats = tx_stats_struct(i);
                    if(tx_stats.channel == channel)
                        index = i;
                        break;
                    end
                end
                if(index < 0)
                    tx_stats.channel = channel;
                    tx_stats.number_of_slots = [];
                    tx_stats.mcs = [];
                    tx_stats.coding_time = [];
                    tx_stats.tx_gain = [];
                    tx_stats.timestamp_diff = [];
                    tx_stats_struct = [tx_stats_struct, tx_stats];
                    index = number_ot_tx_stats + 1;
                end
            end
            
            % *** Now parse the values: TX slots, MCS, Coding Time ***
            
            % Number of TX slots.
            desired_str_delimiters = find(tline==':',5);
            end_of_desired_str = find(tline=='-',2);
            num_of_tx_slots_str = tline(desired_str_delimiters(5)+2:end_of_desired_str(2)-2);
            num_of_tx_slots = str2num(['int64(' num_of_tx_slots_str ')']);
            tx_stats.number_of_slots = [tx_stats.number_of_slots, num_of_tx_slots];
            %fprintf(1,'\t Number of TX slots: %d\n',num_of_tx_slots);
            
            % MCS
            desired_str_delimiters = find(tline==':',7);
            end_of_desired_str = find(tline=='-',4);
            mcs_string = tline(desired_str_delimiters(7)+2:end_of_desired_str(4)-2);
            mcs = str2num(['int8(' mcs_string ')']);
            tx_stats.mcs = [tx_stats.mcs, mcs];
            %fprintf(1,'\t Old MCS: %d\n',old_mcs);
            
            % Coding Time
            desired_str_delimiters = find(tline==':',11);
            end_of_desired_str = find(tline=='[',4);
            if(length(desired_str_delimiters) == 11 && length(end_of_desired_str) == 4)
                coding_time_str = tline(desired_str_delimiters(11)+2:end_of_desired_str(4)-2);
                coding_time = str2num(coding_time_str);
                tx_stats.coding_time = [tx_stats.coding_time, coding_time];
                %fprintf(1,'\t Coding time: %f\n',coding_time);
            else
                tx_stats.coding_time = [tx_stats.coding_time, tx_stats.coding_time(length(tx_stats.coding_time))];
            end
            
            % Timestamp diff.
            time_diff = tx_stats_timestamp - first_timestamp;
            tx_stats.timestamp_diff = [tx_stats.timestamp_diff, time_diff];
            
            % Add TX stats struct back to QUEUE.
            tx_stats_struct(index) = tx_stats;
        end
        
        %% ------------------------------------------------------------------
        % Find line with RX stats report.       
        ret = strfind(tline,string3_to_look_for);
        if(~isempty(ret))
            %fprintf(1,'%s\n',tline);
            % *** Get log timestamp. ***
            rx_stats_timestamp = str2double(tline(28:29))*3600 + str2double(tline(31:32))*60 + str2double(tline(34:35)) + str2double(tline(36:42));
            
            % *** Retrieve channel from log. ***
            end_of_desired_str = find(tline==':',6);
            aux_str = tline(end_of_desired_str(6)+2:end);
            end_of_desired_str = find(aux_str=='-',1);
            channel_string = aux_str(1:end_of_desired_str-2);
            channel = str2num(['int64(' channel_string ')']);
            %fprintf(1,'Channel: %d\n',channel);
            
            % *** Add channel to struct. ***
            if(isempty(rx_stats_struct))
                rx_stats.channel = channel;
                rx_stats.number_of_slots = [];
                rx_stats.mcs = [];
                rx_stats.decoding_time = [];
                rx_stats.cfo = [];
                rx_stats.peak = [];
                rx_stats.noise = [];
                rx_stats.rssi = [];
                rx_stats.snr = [];
                rx_stats.rsrq = [];
                rx_stats.cqi = [];
                rx_stats.error = [];
                rx_stats.noi = [];
                rx_stats.total_number_of_slots = [];
                rx_stats.timestamp_diff = [];
                rx_stats_struct = [rx_stats_struct, rx_stats];
                index = 1;
            else
                number_ot_rx_stats = length(rx_stats_struct);
                index = -1;
                for i=1:1:number_ot_rx_stats
                    rx_stats = rx_stats_struct(i);
                    if(rx_stats.channel == channel)
                        index = i;
                        break;
                    end
                end
                if(index < 0)
                    rx_stats.channel = channel;
                    rx_stats.number_of_slots = [];
                    rx_stats.mcs = [];
                    rx_stats.decoding_time = [];
                    rx_stats.cfo = [];
                    rx_stats.peak = [];
                    rx_stats.noise = [];
                    rx_stats.rssi = [];
                    rx_stats.snr = [];
                    rx_stats.rsrq = [];
                    rx_stats.cqi = [];
                    rx_stats.error = [];
                    rx_stats.noi = [];
                    rx_stats.total_number_of_slots = [];
                    rx_stats.timestamp_diff = [];
                    rx_stats_struct = [rx_stats_struct, rx_stats];
                    index = number_ot_rx_stats + 1;
                end
            end
            
            % *** Now parse the values:  ***
            
            % Number of RX slots.
            desired_str_delimiters = find(tline==':',5);
            end_of_desired_str = find(tline=='-',2);
            if(length(desired_str_delimiters) == 5 && length(end_of_desired_str) == 2)
                num_of_rx_slots_str = tline(desired_str_delimiters(5)+2:end_of_desired_str(2)-2);
                num_of_rx_slots = str2num(['int64(' num_of_rx_slots_str ')']);
                rx_stats.number_of_slots = [rx_stats.number_of_slots, num_of_rx_slots];
                %fprintf(1,'\t Number of TX slots: %d\n',num_of_tx_slots);
            else
                rx_stats.number_of_slots = [rx_stats.number_of_slots, rx_stats.number_of_slots(length(rx_stats.number_of_slots))];
            end
            
            % CFO
            desired_str_delimiters = find(tline==':',7);
            end_of_desired_str = find(tline=='[',4);
            if(length(desired_str_delimiters) == 7 && length(end_of_desired_str) == 4)
                cfo_string = tline(desired_str_delimiters(7)+2:end_of_desired_str(4)-2);
                cfo = str2num(cfo_string);
                rx_stats.cfo = [rx_stats.cfo, cfo];
                %fprintf(1,'\t CFO: %f\n',cfo);
            else
                rx_stats.cfo = [rx_stats.cfo, rx_stats.cfo(length(rx_stats.cfo))];
            end
            
            % Peak value
            desired_str_delimiters = find(tline==':',8);
            end_of_desired_str = find(tline=='N',2);
            if(length(desired_str_delimiters) == 8 && length(end_of_desired_str) == 2)
                peak_string = tline(desired_str_delimiters(8)+2:end_of_desired_str(2)-4);
                peak = str2num(peak_string);
                rx_stats.peak = [rx_stats.peak, peak];
                %fprintf(1,'\t Peak Value: %f\n',peak);
            else
                rx_stats.peak = [rx_stats.peak, rx_stats.peak(length(rx_stats.peak))];
            end
            
            % Noise
            desired_str_delimiters = find(tline==':',9);
            end_of_desired_str = find(tline=='R',3);
            if(length(desired_str_delimiters) == 9 && length(end_of_desired_str) == 3)
                noise_string = tline(desired_str_delimiters(9)+2:end_of_desired_str(3)-4);
                noise = str2num(noise_string);
                rx_stats.noise = [rx_stats.noise, noise];
                %fprintf(1,'\t Noise Value: %f\n',noise);    
            else
                rx_stats.noise = [rx_stats.noise, rx_stats.noise(length(rx_stats.noise))];
            end
            
            % RSSI
            desired_str_delimiters = find(tline==':',10);
            end_of_desired_str = find(tline=='[',5);
            if(length(desired_str_delimiters) == 10 && length(end_of_desired_str) == 5)
                rssi_string = tline(desired_str_delimiters(10)+2:end_of_desired_str(5)-2);
                rssi = str2num(rssi_string);
                rx_stats.rssi = [rx_stats.rssi, rssi];
                %fprintf(1,'\t RSSI Value: %f\n',rssi);     
            else
                rx_stats.rssi = [rx_stats.rssi, rx_stats.rssi(length(rx_stats.rssi))];
            end
            
            % SINR
            desired_str_delimiters = find(tline==':',11);
            end_of_desired_str = find(tline=='[',6);
            if(length(desired_str_delimiters) == 11 && length(end_of_desired_str) == 6)
                snr_string = tline(desired_str_delimiters(11)+2:end_of_desired_str(6)-2);
                snr = str2num(snr_string);
                rx_stats.snr = [rx_stats.snr, snr];
                %fprintf(1,'\t SINR Value: %f\n',snr);
            else
                rx_stats.snr = [rx_stats.snr, rx_stats.snr(length(rx_stats.snr))];
            end
            
            % RSRQ
            desired_str_delimiters = find(tline==':',12);
            end_of_desired_str = find(tline=='[',7);
            if(length(desired_str_delimiters) == 12 && length(end_of_desired_str) == 7)
                rsrq_string = tline(desired_str_delimiters(12)+2:end_of_desired_str(7)-2);
                rsrq = str2num(rsrq_string);
                rx_stats.rsrq = [rx_stats.rsrq, rsrq];
                %fprintf(1,'\t RSRQ Value: %f\n',rsrq);    
            else
                rx_stats.rsrq = [rx_stats.rsrq, rx_stats.rsrq(length(rx_stats.rsrq))];
            end
            
            % CQI
            desired_str_delimiters = find(tline==':',13);
            end_of_desired_str = find(tline=='M',1);
            if(length(desired_str_delimiters) == 13 && length(end_of_desired_str) == 1)
                cqi_string = tline(desired_str_delimiters(13)+2:end_of_desired_str(1)-4);
                cqi = str2num(cqi_string);
                rx_stats.cqi = [rx_stats.cqi, cqi];
                %fprintf(1,'\t CQI Value: %f\n',cqi);
            else
                rx_stats.cqi = [rx_stats.cqi, rx_stats.cqi(length(rx_stats.cqi))];
            end
            
            % MCS
            desired_str_delimiters = find(tline==':',14);
            end_of_desired_str = find(tline=='C',5);
            if(length(desired_str_delimiters) == 14 && length(end_of_desired_str) == 5)
                mcs_string = tline(desired_str_delimiters(14)+2:end_of_desired_str(5)-4);
                mcs = str2num(['int8(' mcs_string ')']);
                rx_stats.mcs = [rx_stats.mcs, mcs];
                %fprintf(1,'\t MCS: %d\n',mcs);
            else
                rx_stats.mcs = [rx_stats.mcs, rx_stats.mcs(length(rx_stats.mcs))];
            end
            
            % Total Number of RX slots.
            desired_str_delimiters = find(tline==':',16);
            end_of_desired_str = find(tline=='E',1);
            if(length(desired_str_delimiters) == 16 && length(end_of_desired_str) == 1)
                total_num_of_rx_slots_str = tline(desired_str_delimiters(16)+2:end_of_desired_str(1)-4);
                total_num_of_rx_slots = str2num(['int64(' total_num_of_rx_slots_str ')']);
                rx_stats.total_number_of_slots = [rx_stats.total_number_of_slots, total_num_of_rx_slots];
                %fprintf(1,'\t Total number of RX slots: %d\n',total_num_of_tx_slots);
            else
                rx_stats.total_number_of_slots = [rx_stats.total_number_of_slots, rx_stats.total_number_of_slots(length(rx_stats.total_number_of_slots))];
            end
            
            % Total Number of Wrong RX slots.
            desired_str_delimiters = find(tline==':',17);
            end_of_desired_str = find(tline=='L',1);
            if(length(desired_str_delimiters) == 17 && length(end_of_desired_str) == 1)
                error_str = tline(desired_str_delimiters(17)+2:end_of_desired_str(1)-4);
                error = str2num(['int64(' error_str ')']);
                rx_stats.error = [rx_stats.error, error];
                %fprintf(1,'\t Total number of wrong decoded slots: %d\n',num_of_rx_error_slots);
            else
                rx_stats.error = [rx_stats.error, rx_stats.error(length(rx_stats.error))];
            end
                        
            % Last NOI.
            desired_str_delimiters = find(tline==':',18);
            end_of_desired_str = find(tline=='A',2);
            if(length(desired_str_delimiters) == 18 && length(end_of_desired_str) == 2)
                noi_str = tline(desired_str_delimiters(18)+2:end_of_desired_str(2)-4);
                noi = str2num(['int64(' noi_str ')']);
                rx_stats.noi = [rx_stats.noi, noi];
                %fprintf(1,'\t NOI: %d\n',noi);
            else
                rx_stats.noi = [rx_stats.noi, rx_stats.noi(length(rx_stats.noi))];
            end
            
            % Decoding Time
            desired_str_delimiters = find(tline==':',20);
            end_of_desired_str = find(tline=='[',8);
            if(length(desired_str_delimiters) == 20 && length(end_of_desired_str) == 8)
                decoding_time_str = tline(desired_str_delimiters(20)+2:end_of_desired_str(8)-2);
                decoding_time = str2num(decoding_time_str);
                rx_stats.decoding_time = [rx_stats.decoding_time, decoding_time];
                %fprintf(1,'\t Decoding time: %f\n',decoding_time);
            else
                rx_stats.decoding_time = [rx_stats.decoding_time, rx_stats.decoding_time(length(rx_stats.decoding_time))];
            end
            
            % Timestamp diff.
            time_diff = rx_stats_timestamp - first_timestamp;
            rx_stats.timestamp_diff = [rx_stats.timestamp_diff, time_diff];
            
            % Add TX stats struct back to QUEUE.
            rx_stats_struct(index) = rx_stats;
        end            
        
        %% ------------------------------------------------------------------
        % Find line with Wrong Decoding RX stats report.       
        ret = strfind(tline,string4_to_look_for);
        if(~isempty(ret))
            %fprintf(1,'%s\n',tline);
            % *** Get log timestamp. ***
            wrong_rx_stats_timestamp = str2double(tline(28:29))*3600 + str2double(tline(31:32))*60 + str2double(tline(34:35)) + str2double(tline(36:42));
            
            % *** Retrieve channel from log. ***
            end_of_desired_str = find(tline==':',6);
            aux_str = tline(end_of_desired_str(6)+2:end);
            end_of_desired_str = find(aux_str=='-',1);
            channel_string = aux_str(1:end_of_desired_str-2);
            channel = str2num(['int64(' channel_string ')']);
            %fprintf(1,'Channel: %d\n',channel);
            
            % *** Add channel to struct. ***
            if(isempty(wrong_rx_stats_struct))
                wrong_rx_stats.channel = channel;
                wrong_rx_stats.number_of_slots = [];
                wrong_rx_stats.peak = [];
                wrong_rx_stats.noise = [];
                wrong_rx_stats.rssi = [];
                wrong_rx_stats.cfi = [];
                wrong_rx_stats.dci = [];
                wrong_rx_stats.noi = [];
                wrong_rx_stats.timestamp_diff = [];
                wrong_rx_stats_struct = [wrong_rx_stats_struct, wrong_rx_stats];
                index = 1;
            else
                wrong_number_ot_rx_stats = length(wrong_rx_stats_struct);
                index = -1;
                for i=1:1:wrong_number_ot_rx_stats
                    wrong_rx_stats = wrong_rx_stats_struct(i);
                    if(wrong_rx_stats.channel == channel)
                        index = i;
                        break;
                    end
                end
                if(index < 0)
                    wrong_rx_stats.channel = channel;
                    wrong_rx_stats.number_of_slots = [];
                    wrong_rx_stats.peak = [];
                    wrong_rx_stats.noise = [];
                    wrong_rx_stats.rssi = [];
                    wrong_rx_stats.cfi = [];
                    wrong_rx_stats.dci = [];
                    wrong_rx_stats.noi = [];
                    wrong_rx_stats.timestamp_diff = [];
                    wrong_rx_stats_struct = [wrong_rx_stats_struct, wrong_rx_stats];
                    index = wrong_number_ot_rx_stats + 1;
                end
            end
            
            % *** Now parse the values:  ***
            
            % Number of Wrong decoded RX slots.
            desired_str_delimiters = find(tline==':',5);
            end_of_desired_str = find(tline=='-',2);
            num_of_rx_wrong_slots_str = tline(desired_str_delimiters(5)+2:end_of_desired_str(2)-2);
            num_of_wrong_rx_slots = str2num(['int64(' num_of_rx_wrong_slots_str ')']);
            wrong_rx_stats.number_of_slots = [wrong_rx_stats.number_of_slots, num_of_wrong_rx_slots];
            %fprintf(1,'\t Number of TX slots: %d\n',num_of_wrong_rx_slots);
            
            % Peak value
            desired_str_delimiters = find(tline==':',7);
            end_of_desired_str = find(tline=='R',3);
            peak_string = tline(desired_str_delimiters(7)+2:end_of_desired_str(3)-4);
            peak = str2num(peak_string);
            wrong_rx_stats.peak = [wrong_rx_stats.peak, peak];
            %fprintf(1,'\t Peak Value: %f\n',peak);
                        
            % RSSI
            desired_str_delimiters = find(tline==':',8);
            end_of_desired_str = find(tline=='[',4);
            rssi_string = tline(desired_str_delimiters(8)+2:end_of_desired_str(4)-2);
            rssi = str2num(rssi_string);
            wrong_rx_stats.rssi = [wrong_rx_stats.rssi, rssi];
            %fprintf(1,'\t RSSI Value: %f\n',rssi);             
            
            % CFI.
            desired_str_delimiters = find(tline==':',9);
            end_of_desired_str = find(tline=='F',3);
            cfi_str = tline(desired_str_delimiters(9)+2:end_of_desired_str(3)-4);
            cfi = str2num(['int64(' cfi_str ')']);
            wrong_rx_stats.cfi = [wrong_rx_stats.cfi, cfi];
            %fprintf(1,'\t CFI: %d\n',cfi);                       
            
            % DCI.
            desired_str_delimiters = find(tline==':',10);
            end_of_desired_str = find(tline=='L',1);
            dci_str = tline(desired_str_delimiters(10)+2:end_of_desired_str(1)-4);
            dci = str2num(['int64(' dci_str ')']);
            wrong_rx_stats.dci = [wrong_rx_stats.dci, dci];
            %fprintf(1,'\t DCI: %d\n',dci);           
            
            % Last NOI.
            desired_str_delimiters = find(tline==':',11);
            end_of_desired_str = find(tline=='A',2);
            noi_str = tline(desired_str_delimiters(11)+2:end_of_desired_str(2)-4);
            noi = str2num(['int64(' noi_str ')']);
            wrong_rx_stats.noi = [wrong_rx_stats.noi, noi];
            %fprintf(1,'\t NOI: %d\n',noi);               
                     
            % Noise
            desired_str_delimiters = find(tline==':',13);
            noise_string = tline(desired_str_delimiters(13)+2:end);
            noise = str2num(noise_string);
            wrong_rx_stats.noise = [wrong_rx_stats.noise, noise];
            %fprintf(1,'\t Noise Value: %f\n',noise);             
            
            % Timestamp diff.
            time_diff = wrong_rx_stats_timestamp - first_timestamp;
            wrong_rx_stats.timestamp_diff = [wrong_rx_stats.timestamp_diff, time_diff];
            
            % Add TX stats struct back to QUEUE.
            wrong_rx_stats_struct(index) = wrong_rx_stats;
        end      
        
        tline = fgetl(fid);
    end
    fclose(fid);
    
    %% Now, plot TX Stats for each channel.
    number_ot_tx_stats = length(tx_stats_struct);
    for i=1:1:number_ot_tx_stats
        
        tx_stats = tx_stats_struct(i);
        
        if(length(tx_stats.timestamp_diff) > 1)
            figure_counter = figure_counter + 1;
            figure(figure_counter);
            
            % Change the limits to analyse some specific part of the plot.
            minimum_time_diff = min(tx_stats.timestamp_diff);
            maximum_time_diff = max(tx_stats.timestamp_diff);
            % Figure out maximum and minimum time axis values.
            x_axis_bounds = minimum_time_diff:maximum_time_diff;
            
            % Plot Number o TX slots.
            plot(tx_stats.timestamp_diff, tx_stats.number_of_slots,'b','linewidth',2);
            hold on
            
            % Plot MCS.
            plot(tx_stats.timestamp_diff, tx_stats.mcs,'r','linewidth',2);
            % Plot Average MCS.
            avg_mcs = sum(tx_stats.mcs)/length(tx_stats.mcs);
            plot(x_axis_bounds, avg_mcs*ones(1,length(x_axis_bounds)),'--r','linewidth',2);
            avg_mcs_legend_str = sprintf('TXed Avg. MCS: %1.2f',avg_mcs);
            
            % Plot coding time.
            plot(tx_stats.timestamp_diff, tx_stats.coding_time,'k','linewidth',2);
            % Plot Average coding time.
            avg_coding_time = sum(tx_stats.coding_time)/length(tx_stats.coding_time);
            plot(x_axis_bounds, avg_coding_time*ones(1,length(x_axis_bounds)),'--k','linewidth',2);
            avg_coding_time_legend_str = sprintf('Avg. Coding Time: %1.2f [ms]',avg_coding_time);   
                                  
            xlim([minimum_time_diff maximum_time_diff]);
            title_str = sprintf('TX Stats - Match: %s - Channel: %d',sub_folder,tx_stats.channel);
            xlabel('Time [s]');
            title(title_str);
            legend('# TX slots','MCS',avg_mcs_legend_str,'Coding Time [ms]', avg_coding_time_legend_str);
            grid on
            hold off
            
            % Save figure.
            scaleFactor = 1.6;
            set(gcf, 'Position', [100, 100, ceil(scaleFactor*560), ceil(scaleFactor*420)])
            saveas_file_name = sprintf('%s%s-tx-stats-channel_%d.png',folder,sub_folder,tx_stats.channel);
            saveas(gcf,saveas_file_name);
        end
    end
    
    %% Now, plot RX Stats for each channel.
    number_ot_rx_stats = length(rx_stats_struct);
    for i=1:1:number_ot_rx_stats
        
        rx_stats = rx_stats_struct(i);
        
        if(length(rx_stats.timestamp_diff) > 1)
            figure_counter = figure_counter + 1;
            fig=figure(figure_counter);
            fig.Name = 'RX Statistics';
            
            % Change the limits to analyse some specific part of the plot.
            minimum_time_diff = min(rx_stats.timestamp_diff);
            maximum_time_diff = max(rx_stats.timestamp_diff);
            % Figure out maximum and minimum time axis values.
            x_axis_bounds = minimum_time_diff:maximum_time_diff;
            
            subplot(2,1,1)
            % Plot Number of RX slots.
            plot(rx_stats.timestamp_diff, rx_stats.number_of_slots,'b','linewidth',2);
            hold on        
            % Plot MCS.
            plot(rx_stats.timestamp_diff, rx_stats.mcs,'r.','linewidth',2);         
            % Calculate average MCS.
            avg_mcs = sum(rx_stats.mcs)/length(rx_stats.mcs);            
            avg_mcs_legend_str = sprintf('MCS - Avg.: %1.2f',avg_mcs);                       
            % Plot NOI.
            plot(rx_stats.timestamp_diff, rx_stats.noi,'g','linewidth',2);            
            % Plot decoding time.
            plot(rx_stats.timestamp_diff, rx_stats.decoding_time,'k','linewidth',2);
            % Plot Average decoding time.
            avg_decoding_time = sum(rx_stats.decoding_time)/length(rx_stats.decoding_time);
            plot(x_axis_bounds, avg_decoding_time*ones(1,length(x_axis_bounds)),'--k','linewidth',2);
            avg_decoding_time_legend_str = sprintf('Avg. Decoding Time: %1.2f [ms]',avg_decoding_time);  
            
            rx_slots_str = sprintf('Total number of received slots: %d - Errors: %d',rx_stats.total_number_of_slots(length(rx_stats.total_number_of_slots)),rx_stats.error(length(rx_stats.error)));
            text(max(rx_stats.timestamp_diff)/2,max(double(rx_stats.mcs))/2,rx_slots_str);
            
            xlim([minimum_time_diff maximum_time_diff]);
            title_str = sprintf('RX Stats - Match: %s - Channel: %d',sub_folder,rx_stats.channel);
            xlabel('Time [s]');
            title(title_str);
            legend('# RX slots',avg_mcs_legend_str,'NOI','Decoding Time [ms]', avg_decoding_time_legend_str);
            grid on
            hold off           
                                  
            %% ------------------------------------------------------------
            subplot(2,1,2)           
            % Plot CFO.
            plot(rx_stats.timestamp_diff, rx_stats.cfo,'linewidth',2);
            hold on
            % Plot Peak
            plot(rx_stats.timestamp_diff, rx_stats.peak,'linewidth',2);
            % Plot noise               
            plot(rx_stats.timestamp_diff, rx_stats.noise,'linewidth',2);
            % PLot RSSI
            plot(rx_stats.timestamp_diff, rx_stats.rssi,'linewidth',2);
            % Plot SINR
            plot(rx_stats.timestamp_diff, rx_stats.snr,'linewidth',2);
            % Plot RSRQ
            plot(rx_stats.timestamp_diff, rx_stats.rsrq,'linewidth',2);
            % Plot CQI
            plot(rx_stats.timestamp_diff, rx_stats.cqi,'linewidth',2);
                       
            xlim([minimum_time_diff maximum_time_diff]);
            title_str = sprintf('RX Stats - Match: %s - Channel: %d',sub_folder,rx_stats.channel);
            xlabel('Time [s]');
            title(title_str);
            legend('CFO [KHz]','Peak','Noise','RSSI [dBm]','SINR [dB]','RSRQ','CQI');
            grid on
            hold off
            
            % Save figure.
            scaleFactor = 1.6;
            set(gcf, 'Position', [100, 100, ceil(scaleFactor*560), ceil(scaleFactor*420)])
            saveas_file_name = sprintf('%s%s-rx-stats-channel_%d.png',folder,sub_folder,rx_stats.channel);
            saveas(gcf,saveas_file_name);
        end
    end    
    
    %% Now, plot Wrong RX Stats for each channel.
    number_of_wrong_rx_stats = length(wrong_rx_stats_struct);
    for i=1:1:number_of_wrong_rx_stats
        
        wrong_rx_stats = wrong_rx_stats_struct(i);
        
        if(length(wrong_rx_stats.timestamp_diff) > 1)
            figure_counter = figure_counter + 1;
            fig=figure(figure_counter);
            fig.Name = 'Wrong RX Slots Statistics';
            
            % Change the limits to analyse some specific part of the plot.
            minimum_time_diff = min(wrong_rx_stats.timestamp_diff);
            maximum_time_diff = max(wrong_rx_stats.timestamp_diff);
            % Figure out maximum and minimum time axis values.
            x_axis_bounds = minimum_time_diff:maximum_time_diff;
       
            subplot(2,1,1)
            % Plot Peak.
            plot(wrong_rx_stats.timestamp_diff, wrong_rx_stats.peak,'linewidth',2);
            hold on
            % Plot RSSI.
            plot(wrong_rx_stats.timestamp_diff, wrong_rx_stats.rssi,'linewidth',2);
            % Plot CFI.
            plot(wrong_rx_stats.timestamp_diff, wrong_rx_stats.cfi,'linewidth',2);
            % Plot DCI.
            plot(wrong_rx_stats.timestamp_diff, wrong_rx_stats.dci,'linewidth',2);
            % Plot NOI.
            plot(wrong_rx_stats.timestamp_diff, wrong_rx_stats.noi,'linewidth',2);
            
            wrong_rx_slots_str = sprintf('Total number of wrong decoded slots: %d',wrong_rx_stats.number_of_slots(length(wrong_rx_stats.number_of_slots)));
            text(max(wrong_rx_stats.timestamp_diff)/2,mean(wrong_rx_stats.rssi)/2,wrong_rx_slots_str);
             
            xlim([minimum_time_diff maximum_time_diff]);
            title_str = sprintf('Wrong RX Stats - Match: %s - Channel: %d',sub_folder,wrong_rx_stats.channel);
            xlabel('Time [s]');
            title(title_str);
            legend('Peak','RSSI [dBm]','CFI','DCI','NOI');
            grid on
            hold off     
            
            subplot(2,1,2)
            % Plot Noise.
            plot(wrong_rx_stats.timestamp_diff, wrong_rx_stats.noise,'linewidth',2);          
            xlim([minimum_time_diff maximum_time_diff]);
            title_str = sprintf('Wrong RX Stats - Match: %s - Channel: %d',sub_folder,wrong_rx_stats.channel);
            xlabel('Time [s]');
            title(title_str);
            legend('Noise');
            grid on
            
            % Save figure.
            scaleFactor = 1.6;
            set(gcf, 'Position', [100, 100, ceil(scaleFactor*560), ceil(scaleFactor*420)])
            saveas_file_name = sprintf('%s%s-wrong-rx-stats-channel_%d.png',folder,sub_folder,wrong_rx_stats.channel);
            saveas(gcf,saveas_file_name);
        end
    end
end
