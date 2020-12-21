// This file is part of MSGPU project.
// Copyright (C) 2020 Mateusz Stadnik
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#ifndef MCU_INTERFACE_H
#define MCU_INTERFACE_H

#include <cstdint> 
#include <mutex> 
#include <thread>
#include <queue>

#include <Vmsgpu.h>

class McuInterface
{
public:
    enum class State : uint8_t 
    {
        Initialize,
        Idle,
        BusHigh,
        BusLow
    };
    McuInterface();

    void send_data(uint8_t data);
    void send_command(uint8_t command);
    
    using bus_type = decltype(std::declval<Vmsgpu>().mcu_bus);
    using clock_type = decltype(std::declval<Vmsgpu>().mcu_bus_clock);
    using cd_type = decltype(std::declval<Vmsgpu>().mcu_bus_command_data);

    void process(uint64_t tick, bus_type& mcu_bus, clock_type& mcu_bus_clock, cd_type& mcu_bus_command_data);
private:
    struct Data 
    {
        bool is_command;
        uint8_t data;
    };

    State state_;
    uint8_t counter_;
    uint8_t bus_state_;
    std::mutex queue_mutex_;
    std::queue<Data> fifo_;
};

#endif // MCU_INTERFACE_H

