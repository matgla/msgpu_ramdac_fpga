#include "Vmsgpu.h"
#include "verilated.h"

#include <memory>

int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);
    Vmsgpu* top = new Vmsgpu();
    while (!Verilated::gotFinish())
    {
        top->eval();
    }
    return 0;
}
