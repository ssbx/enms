%% Generated by the Erlang ASN.1 compiler version:2.0.3
%% Purpose: Erlang record definitions for each named and unnamed
%% SEQUENCE and SET, and macro definitions for each value
%% definition,in module ModTracker



-record('PermConf',{
read, write}).

-record('Property',{
key, value}).

-record('ProbeConf',{
name, type}).

-record('ProbeInfo',{
channel, probeId, name, type, probeMod, status, step, timeout, infoType}).

-record('ProbeActivity',{
channel, probeId, timestamp, state, returnStatus, textual}).

-record('KeyVal',{
key, val}).

-record('ProbeReturn',{
channel, probeId, status, originalReply, timestamp, keysVals}).

-record('ProbeModuleInfo',{
name, info}).

-record('ProbeDump',{
channel, probeId, probeType, probeModule, binaryData}).

-record('ProbeFetch',{
channel, probe, probeType, probeValue}).

-record('TargetInfo',{
channel, properties, type}).

-record('CommandResponce',{
cmdId, cmdMsg}).

-record('TargetCreate',{
ipAdd, hostname, sysName, permConf, cmdId}).

-record('ProbeCreate',{
target, probeConf}).

-record('TargetUpdate',{
target}).

-record('TargetDelete',{
target}).

-record('ProbeUpdate',{
target, probe}).

-record('ProbeDelete',{
target, probe}).

