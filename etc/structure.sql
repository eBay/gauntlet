-- phpMyAdmin SQL Dump
-- version 3.3.2deb1ubuntu1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jul 09, 2012 at 09:10 PM
-- Server version: 5.1.63
-- PHP Version: 5.3.2-1ubuntu4.17

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `gauntlet`
--

-- --------------------------------------------------------

--
-- Table structure for table `hostgroups`
--

DROP TABLE IF EXISTS `hostgroups`;
CREATE TABLE IF NOT EXISTS `hostgroups` (
  `hostgroup` varchar(64) NOT NULL,
  `hostname` varchar(128) NOT NULL,
  UNIQUE KEY `combo` (`hostgroup`,`hostname`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `hosts`
--

DROP TABLE IF EXISTS `hosts`;
CREATE TABLE IF NOT EXISTS `hosts` (
  `hostname` varchar(64) NOT NULL,
  `domain` varchar(64) NOT NULL,
  `sshkey` varchar(128) DEFAULT NULL,
  `altuser` varchar(32) DEFAULT NULL,
  `active` tinyint(1) DEFAULT NULL,
  `sudo` tinyint(1) DEFAULT NULL,
  UNIQUE KEY `fqdn` (`hostname`,`domain`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
CREATE TABLE IF NOT EXISTS `jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(64) NOT NULL,
  `audit` varchar(256) NOT NULL,
  `hostgroup` varchar(64) NOT NULL,
  `started` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=3169 ;

-- --------------------------------------------------------

--
-- Table structure for table `schedule`
--

DROP TABLE IF EXISTS `schedule`;
CREATE TABLE IF NOT EXISTS `schedule` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner` varchar(64) NOT NULL,
  `frequency` varchar(14) NOT NULL,
  `command` varchar(265) NOT NULL,
  `description` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=35 ;

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
CREATE TABLE IF NOT EXISTS `tasks` (
  `jobid` int(11) NOT NULL,
  `hostname` varchar(128) NOT NULL,
  `domain` varchar(128) NOT NULL,
  `audit` varchar(256) NOT NULL,
  `result` text,
  `started` varchar(32) NOT NULL,
  `completed` varchar(32) NOT NULL,
  `status` varchar(32) DEFAULT NULL,
  UNIQUE KEY `hostname` (`hostname`,`domain`,`audit`,`jobid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

