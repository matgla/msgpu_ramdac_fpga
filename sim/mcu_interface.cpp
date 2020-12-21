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

#include "mcu_interface.hpp"

McuInterface::McuInterface() 
    : state_{State::Idle}
    , counter_{0}
    , bus_state_{0}
    , fifo_{} 
{
}

void McuInterface::send_data(uint8_t data) 
{
    std::lock_guard<std::mutex> lock(queue_mutex_);
    fifo_.push(Data{
        .is_command = false, 
        .data = data
    });
}

void McuInterface::send_command(uint8_t command) 
{
    std::lock_guard<std::mutex> lock(queue_mutex_);
    fifo_.push(Data{
        .is_command = true,
        .data = command 
    });
}

void McuInterface::process(uint64_t tick, bus_type& mcu_bus, clock_type& mcu_bus_clock, cd_type& mcu_bus_command_data)
{
    std::lock_guard<std::mutex> lock(queue_mutex_);
    switch (state_) 
    {
        case State::Initialize: 
        {
            mcu_bus_clock = 0;
            mcu_bus_command_data = 0;
            state_ = State::Idle;
        } break;
        case State::Idle: 
        {
            if (fifo_.size())
            {
                const auto data = fifo_.front();
                if (data.is_command) 
                {
                    mcu_bus_command_data = 0;
                }
                else 
                {
                    mcu_bus_command_data = 1;
                }
                bus_state_ = data.data;
                fifo_.pop();
                state_ = State::BusHigh;
                counter_ = 2;
            }
        } break; 
        case State::BusHigh: 
        {
            mcu_bus_clock = 1;
            if (--counter_ == 0)
            {
                state_ = State::BusLow;
                counter_ = 2;
            }
        } break; 
        case State::BusLow: 
        {
            mcu_bus_clock = 0;
            if (--counter_ == 0)
            {
                state_ = State::Idle;
            }
        } break;
    }
    mcu_bus = bus_state_;
}


