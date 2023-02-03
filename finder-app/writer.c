#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main (int argc, char *argv[]) {
   if (argc != 3) {
	return 1;
	} 


	FILE * fp;

   fp = fopen (argv[1], "w+");
	if (fp >= 0) {
 	fprintf(fp, "%s", argv[2]);
	openlog("Writer", LOG_NDELAY, LOG_DAEMON);
	syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
   
	} else {
	openlog("Writer", LOG_NDELAY, LOG_DAEMON);
	syslog(LOG_ERR, "Could not open file");
   }
   if (fclose(fp)>= 0) {
	return (0);
	} else {
	openlog("Writer", LOG_NDELAY, LOG_DAEMON);
	syslog(LOG_ERR, "Could not close file");
}
   
   return(1);
}

