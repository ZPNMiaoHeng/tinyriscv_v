#include <stdint.h>

#include "../include/spi.h"


void spi0_set_clk_div(uint16_t div)
{
    SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CLK_DIV_MASK << SPI_CTRL0_CLK_DIV_OFFSET);
    SPI0_REG(SPI_CTRL0_REG_OFFSET) |= div << SPI_CTRL0_CLK_DIV_OFFSET;
}

void spi0_set_role_mode(spi_role_mode_e mode)
{
    if (mode == SPI_ROLE_MODE_MASTER)
        SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_ROLE_MODE_BIT);
    else
        SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_ROLE_MODE_BIT;
}

void spi0_set_spi_mode(spi_spi_mode_e mode)
{
    switch (mode) {
        case SPI_MODE_STANDARD:
            SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SPI_MODE_MASK << SPI_CTRL0_SPI_MODE_OFFSET);
            break;

        case SPI_MODE_DUAL:
            SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SPI_MODE_MASK << SPI_CTRL0_SPI_MODE_OFFSET);
            SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_SPI_MODE_OFFSET;
            break;

        case SPI_MODE_QUAD:
            SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SPI_MODE_MASK << SPI_CTRL0_SPI_MODE_OFFSET);
            SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 2 << SPI_CTRL0_SPI_MODE_OFFSET;
            break;
    }
}

void spi0_set_cp_mode(spi_cp_mode_e mode)
{
    switch (mode) {
        case SPI_CPOL_0_CPHA_0:
            SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CP_MODE_MASK << SPI_CTRL0_CP_MODE_OFFSET);
            break;

        case SPI_CPOL_0_CPHA_1:
            SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CP_MODE_MASK << SPI_CTRL0_CP_MODE_OFFSET);
            SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_CP_MODE_OFFSET;
            break;

        case SPI_CPOL_1_CPHA_0:
            SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CP_MODE_MASK << SPI_CTRL0_CP_MODE_OFFSET);
            SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 2 << SPI_CTRL0_CP_MODE_OFFSET;
            break;

        case SPI_CPOL_1_CPHA_1:
            SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 3 << SPI_CTRL0_CP_MODE_OFFSET;
            break;
    }
}

void spi0_set_enable(uint8_t en)
{
    if (en)
        SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_ENABLE_BIT;
    else
        SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_ENABLE_BIT);
}

void spi0_set_interrupt_enable(uint8_t en)
{
    if (en)
        SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_INT_EN_BIT;
    else
        SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_INT_EN_BIT);
}

void spi0_set_msb_first()
{
    SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_MSB_FIRST_BIT;
}

void spi0_set_lsb_first()
{
    SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_MSB_FIRST_BIT);
}

void spi0_set_txdata(uint8_t data)
{
    SPI0_REG(SPI_TXDATA_REG_OFFSET) |= data;
}

uint8_t spi0_get_rxdata()
{
    return (SPI0_REG(SPI_RXDATA_REG_OFFSET));
}

uint8_t spi0_reset_rxfifo()
{
    uint8_t data;

    data = 0;

    while (!(SPI0_REG(SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_RX_FIFO_EMPTY_BIT))) {
        data = SPI0_REG(SPI_RXDATA_REG_OFFSET);
    }

    return data;
}

void spi0_set_ss_ctrl_by_sw(uint8_t yes)
{
    if (yes)
        SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_SS_SW_CTRL_BIT;
    else
        SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_SS_SW_CTRL_BIT);
}

void spi0_set_ss_level(uint8_t level)
{
    if (level)
        SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_SS_LEVEL_BIT;
    else
        SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_SS_LEVEL_BIT);
}

uint8_t spi0_tx_fifo_full()
{
    if (SPI0_REG(SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_TX_FIFO_FULL_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi0_tx_fifo_empty()
{
    if (SPI0_REG(SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_TX_FIFO_EMPTY_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi0_rx_fifo_full()
{
    if (SPI0_REG(SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_RX_FIFO_FULL_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi0_rx_fifo_empty()
{
    if (SPI0_REG(SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_RX_FIFO_EMPTY_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi0_get_interrupt_pending()
{
    if (SPI0_REG(SPI_CTRL0_REG_OFFSET) & (1 << SPI_CTRL0_INT_PENDING_BIT))
        return 1;
    else
        return 0;
}

void spi0_clear_interrupt_pending()
{
    SPI0_REG(SPI_CTRL0_REG_OFFSET) |= (1 << SPI_CTRL0_INT_PENDING_BIT);
}

void spi0_master_set_read()
{
    SPI0_REG(SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_READ_BIT;
}

void spi0_master_set_write()
{
    SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_READ_BIT);
}

void spi0_master_set_ss_delay(uint8_t clk_num)
{
    SPI0_REG(SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SS_DELAY_MASK << SPI_CTRL0_SS_DELAY_OFFSET);
    SPI0_REG(SPI_CTRL0_REG_OFFSET) |= (clk_num & SPI_CTRL0_SS_DELAY_MASK) << SPI_CTRL0_SS_DELAY_OFFSET;
}

uint8_t spi0_master_transmiting()
{
    if (SPI0_REG(SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_BUSY_BIT))
        return 1;
    else
        return 0;
}

void spi0_master_write_bytes(uint8_t write_data[], uint32_t count)
{
    uint32_t i;

    spi0_master_set_write();

    for (i = 0; i < count; i++) {
        spi0_set_txdata(write_data[i]);
        while (spi0_master_transmiting());
    }
}

void spi0_master_read_bytes(uint8_t read_data[], uint32_t count)
{
    uint32_t i;

    spi0_master_set_read();

    for (i = 0; i < count; i++) {
        spi0_set_txdata(0xff);
        while (spi0_master_transmiting());
        read_data[i] = spi0_get_rxdata();
    }
}
