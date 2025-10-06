// Macros to build include file name
#ifndef symbols_header
#define _quoted_string(x) #x
#define quoted_string(x) _quoted_string(x)
#define _symbols_header(x) _quoted_string(x##__Syms.h)
#define symbols_header(x) _symbols_header(x)
#endif
// Top level
#include symbols_header(VM_PREFIX)
// Helpers
#include "../../verilator_helpers/clock_gen/clock_gen.h"
#include "../../verilator_helpers/video_out/video_out.h"

#if VM_TRACE
#include "verilated_vcd_c.h"
#endif

// Period for a ~27 MHz clock
#define PERIOD_27MHz_ps    ((vluint64_t)1000000/27)

// Top level (global)
VM_PREFIX* top;

// Clocks generation (global)
ClockGen *clk;

// Video output
VideoOut* vga;

int main(int argc, char **argv, char **env)
{
    // Simulation duration
    clock_t    beg, end;
    double     secs;
    // Trace index
    int        trc_idx = 0;
    int        min_idx = 0;
    bool       vs      = false;
    // File name generation
    char       file_name[256];
    // Simulation time
    vluint64_t tb_time;
    vluint64_t max_time;
    // Testbench configuration
    const char *arg;

    beg = clock();

    // Parse parameters
    Verilated::commandArgs(argc, argv);

    // Default : 1 msec
    max_time = (vluint64_t)1000000000;

    // Simulation duration : +usec=<num>
    arg = Verilated::commandArgsPlusMatch("usec=");
    if ((arg) && (arg[0]))
    {
        arg += 6;
        max_time = (vluint64_t)atoi(arg) * (vluint64_t)1000000;
    }

    // Simulation duration : +msec=<num>
    arg = Verilated::commandArgsPlusMatch("msec=");
    if ((arg) && (arg[0]))
    {
        arg += 6;
        max_time = (vluint64_t)atoi(arg) * (vluint64_t)1000000000;
    }

    // Trace start index : +tidx=<num>
    arg = Verilated::commandArgsPlusMatch("tidx=");
    if ((arg) && (arg[0]))
    {
        arg += 6;
        min_idx = atoi(arg);
    }
    else
    {
        min_idx = 0;
    }
    
    // Init top verilog instance
    top = new VM_PREFIX;

    // Initialize clock generator
    clk = new ClockGen(1);
    tb_time = (vluint64_t)0;
    // 27 MHz clock
    clk->NewClock(0, PERIOD_27MHz_ps);
    clk->ConnectClock(0, &top->CLK_i);
    clk->StartClock(0, tb_time);
    
    // Init video output C++ model
    vga = new VideoOut(0, 8, 0, 0, 720, 0, 480, "snapshot");

#if VM_TRACE
    // Init VCD trace dump
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->spTrace()->set_time_resolution ("1 ps");
    if (trc_idx == min_idx)
    {
        sprintf(file_name, quoted_string(VM_PREFIX) "_%04d.vcd", trc_idx);
        printf("Opening VCD file \"%s\"\n", file_name);
        tfp->open (file_name);
    }
#endif /* VM_TRACE */

    // RESET ON
    top->RST_i = 1;

    // Reset pulse = 1 µs
    while (tb_time < 1000000)
    {
        // Toggle clocks
        clk->AdvanceClocks(tb_time, true);
        // Evaluate verilated model
        top->eval ();
        
#if VM_TRACE
        // Dump signals into VCD file
        if (tfp)
        {
            if (trc_idx >= min_idx) tfp->dump (tb_time);
        }
#endif /* VM_TRACE */

        if (Verilated::gotFinish()) break;
    }

    // RESET OFF
    top->RST_i = 0;

    // Simulation loop
    while (tb_time < max_time)
    {
        // Toggle clocks
        clk->AdvanceClocks(tb_time, true);
        // Evaluate verilated model
        top->eval ();
        
        // Dump Video output
        vs = vga->eval_RGB444_DE (top->CLK_i,
                                  top->VID_HVD_o & 1,
                                  top->VID_R_o,  top->VID_G_o,  top->VID_B_o);

#if VM_TRACE
        // Dump signals into VCD file
        if (tfp)
        {
            if (vs)
            {
                // New VCD file
                if (trc_idx >= min_idx) tfp->close();
                trc_idx++;
                if (trc_idx >= min_idx)
                {
                    sprintf(file_name, quoted_string(VM_PREFIX) "_%04d.vcd", trc_idx);
                    printf("Opening VCD file \"%s\"\n", file_name);
                    tfp->open (file_name);
                }
            }
            
            if (trc_idx >= min_idx) tfp->dump (tb_time);
        }
#endif /* VM_TRACE */

        if (Verilated::gotFinish()) break;
    }

#if VM_TRACE
    if (tfp && trc_idx >= min_idx) tfp->close();
#endif /* VM_TRACE */

    top->final();

    delete top;

    delete clk;

    // Calculate running time
    end = clock();
    printf("\nSeconds elapsed : %5.3f\n", (float)(end - beg) / CLOCKS_PER_SEC);

    exit(0);
}
