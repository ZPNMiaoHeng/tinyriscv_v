#ifndef _FLASH_W25Q_H_
#define _FLASH_W25Q_H_



#define CMD_READ_ID                             (0x90)
#define CMD_READ_ID_QUAD                        (0x94)
#define CMD_READ_STATUS_REG2                    (0x35)
#define CMD_WRITE_STATUS_REG2                   (0x31)
#define CMD_WRITE_ENABLE_FOR_VOL_STATUS_REG     (0x50)


typedef struct {
    uint8_t manf_id;
    uint8_t device_id;
} w25q_id_t;

void flash_w25q_init(uint16_t clk_div);
w25q_id_t flash_w25q_read_id();
void flash_w25q_enable_qspi(uint8_t en);
w25q_id_t flash_w25q_read_id_quad();


#endif
