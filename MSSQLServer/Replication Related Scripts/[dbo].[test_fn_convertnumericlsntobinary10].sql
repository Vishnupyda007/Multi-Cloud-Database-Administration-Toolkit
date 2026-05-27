  
  
-- Convert LastLsn from numeric to binary  
       create function [dbo].[test_fn_convertnumericlsntobinary10](  
    @numericlsn numeric(25,0)  
    ) returns binary(10)  
as  
begin  
    -- Declare components to be one step larger than the intended type  
    -- to avoid sign overflow problems. e.g. convert(smallint,   
    -- convert(numeric(25,0),65535)) will fail but convert(binary(2),   
    -- convert(int,convert(numeric(25,0),65535))) will give the   
    -- intended result of 0xffff.  
    declare @high4bytelsncomponent bigint,  
            @mid4bytelsncomponent bigint,  
            @low2bytelsncomponent int  
  
    select @high4bytelsncomponent = convert(bigint, floor(@numericlsn / 1000000000000000))  
    select @numericlsn = @numericlsn - convert(numeric(25,0), @high4bytelsncomponent) * 1000000000000000  
    select @mid4bytelsncomponent = convert(bigint,floor(@numericlsn / 100000))  
    select @numericlsn = @numericlsn - convert(numeric(25,0), @mid4bytelsncomponent) * 100000  
    select @low2bytelsncomponent = convert(int, @numericlsn)  
  
    return convert(binary(4), @high4bytelsncomponent) +  
           convert(binary(4), @mid4bytelsncomponent) +  
           convert(binary(2), @low2bytelsncomponent)  
end  