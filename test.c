#include <iostream>
//#include <fstream>
#include <stdio.h>
#include <wiringPiSPI.h>
using namespace std;

// pass this script the string data to write to the SPI

int main(int argc, char *argv[] ) {
	int chan=0;
	int speed=1000000;
	char* data = argv[1];
	int S;
	S = wiringPiSPISetup(chan, speed);
#cout << argv[1] << "\n";
	unsigned char buff[100];
	buff[0] = argv[1][0];
	buff[1] = argv[1][1];
	//buff = argv[1];
cout << buff << "\n";

	int ret=wiringPiSPIDataRW (chan,buff,100) ;
/*	
	if( wiringPiSPISetup (chan, speed)==-1) {
//		printf(“Could not initialise SPI\n”);
		return -1;
	}
*/
//	write (wiringPiSPIGetFD (chan), data, strlen(data));
	return 1;
/*	
	printf(“When ready hit enter.\n”);
	(void) getchar();// remove the CR
	unsigned char buff[100];
	
	while (1) {

		printf(“Input a string, Input 0 to finish “);
		gets (buff);
		if(buff[0]==’0′) {
			break;
		} else {			
			int ret=wiringPiSPIDataRW (chan,buff,100) ;
			printf (“%s \n”, buff);	
		}
	}
	*/
} 
