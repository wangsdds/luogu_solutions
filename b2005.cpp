#include <bits/stdc++.h>
using namespace std;

int main()
{
    for (int i = 1; i <= 3; i++)
    {
        for (int k = 1; k <= 3 - i; k++) // 外层循环控制每行打印几个空格，第 i 行打印 3-i 个
        {
            cout << " "; // 打印空格
        }
        // 内层循环控制每行打印几个字符，第 i 行打印 i 个
        for (int j = 1; j <= 2 * i - 1; j++)
        {
            cout << "*"; // 打印题目输入的字符 c，而不是硬编码的 *
        }
        cout << "\n"; // 每行打完换行
    }
    return 0;
}