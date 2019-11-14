clear all;close all;clc

LEN = 31;

sch_table = -1*ones(LEN,LEN);

overwrite_cnt = 0;
m0_ = 0;
m1_ = 0;
for idx = 0:1:1024
    
    value = idx;
    
    m0 = mod(m0_, LEN);
    
    m1_ = m1_ + 1;
    m1 = mod(m1_, LEN);
    
    fprintf('value: %d - m0: %d - m1: %d\n', value, m0, m1);
    
    old_value = sch_table(m0+1,m1+1);
    if(old_value > -1)
        overwrite_cnt = overwrite_cnt + 1;
        fprintf(1,'[Overwriting value (%d)] old value: %d - new value: %d - m0: %d - m1: %d\n', overwrite_cnt, old_value, value, m0, m1);
    end
    
    sch_table(m0+1,m1+1) = value;
    
    if(m1_ == 30)
        m0_ = m0_ + 1;
        m1_ = m0_;
    end
    
end

not_in_table_cnt = 0;
for value = 0:1:1023
    
    [row, col] = find(sch_table == value);
    
    if(length(row) > 1 || length(col) > 1)
        fprintf(1,'[Duplicate value] value: %d - %d - %d\n', value, length(row),  length(col));
    end
    
    if(isempty(row) || isempty(col))
        fprintf(1,'[Empty table] value: %d - %d - %d\n', value, length(row),  length(col));
        not_in_table_cnt = not_in_table_cnt + 1;
    end
    
    
end