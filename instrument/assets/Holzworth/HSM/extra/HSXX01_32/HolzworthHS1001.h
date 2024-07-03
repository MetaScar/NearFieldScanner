/*******************************************************************/
/*                                                                 */
/* File Name:   HolzworthHS1001.h                                  */
/*                                                                 */
/* Description:                                                    */
/*                                                                 */
/*    This is the wrapper DLL for calling the methods from         */
/*    Holzworth usb dll                                            */
/*                                                                 */
/*******************************************************************/

#ifdef __cplusplus
#define HOLZ_INIT extern "C" __declspec(dllexport)
#else
#define HOLZ_INIT __declspec(dllexport)
#endif

//Use the functions below for HSM or legacy
HOLZ_INIT int open_device(const char *manuf, const char *devname, const char *serialnum);
HOLZ_INIT char* getAttachedDevices();
HOLZ_INIT int openDevice(const char *serialnum);
HOLZ_INIT int deviceAttached(const char *serialnum);
HOLZ_INIT short openDeviceVB(const char *serialnum);
HOLZ_INIT void close_all (void);

//Use the function below for HSM only
HOLZ_INIT int openHolzSocket(const char *ipAddr);
HOLZ_INIT char* usbCommWrite(const char *serialnum, const char *pBuf);
HOLZ_INIT short usbCommWriteVB(const char *serialnum, const char *pBuf, char *returnBufVB);

//Use the functions below for legacy only
HOLZ_INIT int RFPowerOn(const char *serialnum);
HOLZ_INIT int RFPowerOff(const char *serialnum);
HOLZ_INIT short isRFPowerOn(const char *serialnum);
HOLZ_INIT int ReferenceInternal(const char *serialnum);
HOLZ_INIT int ReferenceExternal(const char *serialnum);
HOLZ_INIT int ModEnableNo(const char *serialnum);
HOLZ_INIT int ModEnableFM(const char *serialnum);
HOLZ_INIT int ModEnableAM(const char *serialnum);
HOLZ_INIT int ModEnablePM(const char *serialnum);
HOLZ_INIT int ModEnablePulse(const char *serialnum);
HOLZ_INIT int ModEnableSweep(const char *serialnum);
HOLZ_INIT int setPower(const char *serialnum, short powernum);
HOLZ_INIT int setPowerS(const char *serialnum, const char *powerstr);
HOLZ_INIT short readPower(const char *serialnum);
HOLZ_INIT int setPhase(const char *serialnum, short phasenum);
HOLZ_INIT int setPhaseS(const char *serialnum, const char *phasestr);
HOLZ_INIT short readPhase(const char *serialnum);
HOLZ_INIT int setFrequency(const char *serialnum, long long frequencynum);
HOLZ_INIT int setFrequencyS(const char *serialnum, const char *frequencystr);
HOLZ_INIT long long readFrequency(const char *serialnum);
HOLZ_INIT int setFrequencyStart(const char *serialnum, long long frequencynum);
HOLZ_INIT int setFrequencyStartS(const char *serialnum, const char *frequencystr);
HOLZ_INIT int setFrequencyStop(const char *serialnum, long long frequencynum);
HOLZ_INIT int setFrequencyStopS(const char *serialnum, const char *frequencystr);
HOLZ_INIT int setFrequencyDwell(const char *serialnum, unsigned short dwellnum);
HOLZ_INIT int setFrequencyDwellS(const char *serialnum, const char *dwellstr);
HOLZ_INIT int setFrequencyPoints(const char *serialnum, unsigned short pointsnum);
HOLZ_INIT int setFrequencyPointsS(const char *serialnum, const char *pointsstr);
HOLZ_INIT int setFMDeviation(const char *serialnum, short fmDevnum); 
HOLZ_INIT int setFMDeviationS(const char *serialnum, const char *fmDevstr);
HOLZ_INIT int setAMDepth(const char *serialnum, short amnum);
HOLZ_INIT int setAMDepthS(const char *serialnum, const char *amstr);
HOLZ_INIT int setPMDeviation(const char *serialnum, short pmnum);
HOLZ_INIT int setPMDeviationS(const char *serialnum, const char *pmstr);
HOLZ_INIT int recallFactoryPreset(const char *serialnum);
HOLZ_INIT int recallSavedState(const char *serialnum);
HOLZ_INIT int saveCurrentState(const char *serialnum);
HOLZ_INIT int EnableWideBand(const char *serialnum);
HOLZ_INIT int importWideList(const char *serialnum, const char* filename);
HOLZ_INIT int WideModeFreeRunning(const char *serialnum);
HOLZ_INIT int WideModeTriggerPoint(const char *serialnum);
HOLZ_INIT int WideModeTriggerList(const char *serialnum);
HOLZ_INIT int setWideBandDwellS(const char *serialnum, const char *dwellstr);
HOLZ_INIT int setWideBandDwell(const char *serialnum, long dwellnum);
HOLZ_INIT int EnableNarrowBand(const char *serialnum);
HOLZ_INIT int importNarrowList(const char *serialnum, const char* filename);
HOLZ_INIT int NarrowModeFreeRunning(const char *serialnum);
HOLZ_INIT int NarrowModeTriggerPoint(const char *serialnum);
HOLZ_INIT int NarrowModeTriggerList(const char *serialnum);
HOLZ_INIT int setNarrowBandDwellS(const char *serialnum, const char *dwellstr);
HOLZ_INIT int setNarrowBandDwell(const char *serialnum, long dwellnum);
HOLZ_INIT char* write_string3(const char* serialnum, const char *pBuf);
