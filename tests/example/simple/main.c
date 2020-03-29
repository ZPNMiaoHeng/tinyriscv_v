
static void set_test_pass()
{
    asm("li x27, 0x01");
}

static void set_test_fail()
{
    asm("li x27, 0x00");
}


int mul = 3;
int div = 3;

int main()
{
    int i;
    int sum;

    mul = 6;
    //div = 3;

    sum = 0;

    // sum = 5050
    for (i = 0; i <= 100; i++)
        sum += i;

    // sum = 3775
    for (i = 0; i <= 50; i++)
        sum -= i;

    // sum = 22650
    sum = sum * mul;

    // sum = 7550
    sum = sum / div;

    if (sum == 7550)
        set_test_pass();
    else
        set_test_fail();

    return 0;
}
