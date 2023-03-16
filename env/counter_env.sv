  class counter_env;

        //Instantiate virtual interface with Write BFM modport, Write monitor modport,Read monitor modport
        
        virtual counter_if.WR_BFM wr_if;
        virtual counter_if.WR_MON wrmon_if;
        virtual counter_if.RD_MON rdmon_if;

        //Declare  mailboxes parameterized by counter_trans and construct it
        
        mailbox #(counter_trans) gen2wr = new();
        mailbox #(counter_trans) wr2rm = new();
        mailbox #(counter_trans) rm2sb = new();


        //Create handle for counter_gen,counter_read_bfm,counter_write_bfm,counter_read_mon,counter_model,counter_sb

        counter_gen gen;
        counter_write_bfm wr_bfm;
        counter_write_mon wr_mon;
        counter_read_mon rd_mon;
        counter_model model;
        counter_sb sb;


        //In constructor pass the BFM and monitor interface as the argument
        //and connect with the virtual interfaces of counter_env
        
        function new(virtual counter_if.WR_BFM wr_if,
        virtual counter_if.WR_MON wrmon_if,
        virtual counter_if.RD_MON rdmon_if);

        this.wr_if = wr_if;
        this.wrmon_if = wrmon_if;
        this.rdmon_if = rdmon_if;

        endfunction: new

        //In task build
        //create instances for generator,Read BFM,Write BFM,Write monitor
        //Read monitor,Reference model,Scoreboard
        task build();
                gen = new(gen2wr);
                wr_bfm = new(wr_if, gen2wr);
                wr_mon = new(wrmon_if, wr2rm);
                rd_mon = new(rdmon_if, rd2rm,rd2sb);
                model = new(wr2rm, rd2rm, rm2sb);
                sb = new(rm2sb, rd2sb);
        endtask: build
        
                //Understand and include the reset_dut task

        task reset_dut();
                begin
                        rd_if.rd_drv_cb.rd_address<='0;
                        rd_if.rd_drv_cb.read<='0;

                        wr_if.wr_drv_cb.wr_address<=0;
                        wr_if.wr_drv_cb.write<='0;

                        repeat(5) @(wr_if.wr_drv_cb);
                        for (int i=0; i<4096; i++)
                                begin
                                        wr_if.wr_drv_cb.write<='1;
                                        wr_if.wr_drv_cb.wr_address<=i;
                                        wr_if.wr_drv_cb.data_in<='0;
                                        @(wr_if.wr_drv_cb);
                                end
                        wr_if.wr_drv_cb.write<='0;
                        repeat (5) @(wr_if.wr_drv_cb);
                end
        endtask : reset_dut

        //In start task
        //call all the start methods of generator,Read BFM,Write BFM,Read monitor
        //Write Monitor,reference model,scoreboard

        task start();
                gen.start();
                wr_bfm.start();
                rd_bfm.start();
                wr_mon.start();
                rd_mon.start();
                model.start();
                sb.start();
        endtask:start

        task stop();
                wait(sb.DONE.triggered);
        endtask : stop

        //In run task call resut_dut, start, stop methods & report function from scoreboard
        task run();
                reset_dut();
                start();
                stop();
                sb.report();
        endtask: run

endclass : ram_env


                                                
