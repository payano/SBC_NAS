#define _GNU_SOURCE     /* To get defns of NI_MAXSERV and NI_MAXHOST */
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/if_link.h>
#include <string.h>

static void print_address(uint32_t addr)
{
	for(int i = 0; i < 4;++i) {
		uint8_t octet = addr & 0xff;
		addr = addr >> 8;
		printf("%u", octet);
		if(i != 3) printf(".");
	}
}

static void fprint_address(uint32_t addr, FILE *fd)
{
	for(int i = 0; i < 4;++i) {
		uint8_t octet = addr & 0xff;
		addr = addr >> 8;
		fprintf(fd,"%u", octet);
		if(i != 3) fprintf(fd,".");
	}
}
static int netbits(uint32_t mask)
{
	int count = 0;
	while(1) {
		uint8_t bit = mask & 0x1;
		mask = mask >> 1;
		if(!bit) return count;
		count++;
	}
	return 0;
}

static uint32_t rotate_bits(uint32_t in, int sz)
{
	uint32_t out = 0x0;
	for(int i = 0; i < sz; ++i) {
		int tmp = (in >> ((sz-1) - i)) & 0x1;
		out |= tmp << i;
	}
	return out;
}

static void suggested_ip(uint32_t *new_addr, uint32_t net_addr, uint32_t net_bits)
{
	uint32_t swapped = rotate_bits(net_addr, 32);

	uint32_t add = 2;
	uint32_t test = rotate_bits(add, 32 - net_bits);
	swapped |= test;

	*new_addr = rotate_bits(swapped, 32);
}

int main(int argc, char *argv[])
{
	struct ifaddrs *ifaddr, *ifa;
	int family, s, n;
	char host[NI_MAXHOST];
	int ret = 0;

	if (getifaddrs(&ifaddr) == -1) {
		perror("getifaddrs");
		exit(EXIT_FAILURE);
	}

	/* Walk through linked list, maintaining head pointer so we
          can free list later */
	int nr = 0;
	for (ifa = ifaddr, n = 0; ifa != NULL; ifa = ifa->ifa_next, n++) {
		if (ifa->ifa_addr == NULL)
			continue;

		family = ifa->ifa_addr->sa_family;
		if(family != AF_INET) continue;

		printf("[%d] %s", nr++, ifa->ifa_name);
		s = getnameinfo(ifa->ifa_addr, sizeof(struct sockaddr_in),
				host, NI_MAXHOST,
				NULL, 0, NI_NUMERICHOST);
		if (s != 0) {
			printf("getnameinfo() failed: %s\n", gai_strerror(s));
			exit(EXIT_FAILURE);
		}

		printf(": <%s>\n", host);
	}

	int answer;
	printf("Choose which network interface you will be using: ");
	if(!scanf("%d", &answer)) {
		printf("Wrong answer...\n");
		ret = 1;
		goto exit;
	}

	nr = 0;
	for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
		if (ifa->ifa_addr == NULL)
			continue;

		family = ifa->ifa_addr->sa_family;
		if(family != AF_INET) continue;

		if(answer != nr) {
			++nr;
			continue;
		}

		uint32_t netmask = ((struct sockaddr_in *)(ifa->ifa_netmask))->sin_addr.s_addr;
		uint32_t ipaddr = ((struct sockaddr_in *)(ifa->ifa_addr))->sin_addr.s_addr;
		uint32_t net_addr = netmask & ipaddr;
		uint32_t suggested_addr = net_addr;

		printf("Your network address is: ");
		print_address(net_addr);
		uint8_t network_bits = netbits(netmask);
		printf("/%d\n", network_bits);

		suggested_ip(&suggested_addr, net_addr, network_bits);
		printf("I would suggest that the ip address should be: ");
		print_address(suggested_addr);
		printf("\n");

		char addr[32] = {0,};
		printf("Type in your ip address: ");
		scanf("%s", addr);

		FILE *fd;

		fd = fopen("./settings.txt", "w+");
		if(!fd) {
			printf("could not open file...");
			ret = 1;
			goto exit;
		}
		fprintf(fd,"INTERFACE=\"%s\"\n", ifa->ifa_name);
		fprintf(fd,"IPADDR=\"%s\"\n", addr);
		fprintf(fd,"NETMASK=\"");
		fprint_address(netmask,fd);
		fprintf(fd,"\"\n");
		fprintf(fd,"NET_ADDR=\"");
		fprint_address(net_addr,fd);
		fprintf(fd,"\"\n");
		fprintf(fd,"NET_BITS=\"%d\"\n", network_bits);
		fclose(fd);

		goto exit;
	}

	ret = 1;
	printf("Wrong answer...\n");

exit:
	freeifaddrs(ifaddr);
	exit(ret);
}

