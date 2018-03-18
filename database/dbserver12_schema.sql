-- MySQL dump 10.13  Distrib 5.7.21, for Linux (x86_64)
--
-- Host: localhost    Database: dbserver12
-- ------------------------------------------------------
-- Server version	5.7.21-0ubuntu0.17.10.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `aut_writes_doc`
--

DROP TABLE IF EXISTS `aut_writes_doc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `aut_writes_doc` (
  `aut_writes_docid` int(11) NOT NULL AUTO_INCREMENT,
  `documentid` int(11) NOT NULL DEFAULT '0',
  `authorid` int(11) NOT NULL DEFAULT '0',
  `author_rank` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`aut_writes_docid`),
  KEY `authorid` (`authorid`),
  KEY `documentid` (`documentid`)
) ENGINE=MyISAM AUTO_INCREMENT=466519 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `author`
--

DROP TABLE IF EXISTS `author`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `author` (
  `authorid` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '',
  `address` text,
  PRIMARY KEY (`authorid`),
  KEY `author_index` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=187044 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `book`
--

DROP TABLE IF EXISTS `book`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `book` (
  `bookid` int(11) NOT NULL AUTO_INCREMENT,
  `booktitle` text,
  PRIMARY KEY (`bookid`)
) ENGINE=MyISAM AUTO_INCREMENT=15818 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dataof_in_parameters`
--

DROP TABLE IF EXISTS `dataof_in_parameters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dataof_in_parameters` (
  `documentid` int(20) DEFAULT NULL,
  `sessionid` varchar(50) DEFAULT NULL,
  KEY `sessionid` (`sessionid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `doc_in_parameters`
--

DROP TABLE IF EXISTS `doc_in_parameters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `doc_in_parameters` (
  `documentid` int(11) DEFAULT NULL,
  `sessionid` varchar(50) DEFAULT NULL,
  KEY `sessionid` (`sessionid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `doc_in_question`
--

DROP TABLE IF EXISTS `doc_in_question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `doc_in_question` (
  `questionid` char(50) NOT NULL DEFAULT '',
  `documentid` int(11) DEFAULT '0',
  KEY `questionid` (`questionid`),
  KEY `documentid` (`documentid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `doctype`
--

DROP TABLE IF EXISTS `doctype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `doctype` (
  `doctypeid` int(11) NOT NULL AUTO_INCREMENT,
  `doctype` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`doctypeid`)
) ENGINE=MyISAM AUTO_INCREMENT=140 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `document`
--

DROP TABLE IF EXISTS `document`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `document` (
  `documentid` int(11) NOT NULL AUTO_INCREMENT,
  `refmanid` varchar(50) DEFAULT NULL,
  `title` text NOT NULL,
  `year` varchar(4) DEFAULT NULL,
  `unpublished` varchar(50) DEFAULT NULL,
  `journalid` int(11) DEFAULT NULL,
  `volume` varchar(20) DEFAULT NULL,
  `issue` varchar(20) DEFAULT NULL,
  `bookid` int(11) DEFAULT NULL,
  `chapternumber` varchar(20) DEFAULT NULL,
  `verlagid` int(11) DEFAULT NULL,
  `thesis` text,
  `thesis_ort` text,
  `startpage` int(11) DEFAULT '0',
  `endpage` int(11) DEFAULT NULL,
  `notizen` text,
  `isbn` varchar(20) DEFAULT NULL,
  `abstract` mediumtext,
  `contactaddress` tinyblob,
  `seriesid` int(11) DEFAULT NULL,
  `ownerid` int(11) DEFAULT NULL,
  `doubleflagg` tinyint(4) DEFAULT '0',
  `doctypeid` int(11) DEFAULT NULL,
  `institutionid` int(11) DEFAULT NULL,
  `available` varchar(255) DEFAULT NULL,
  `pdffile` text,
  `inserttime` datetime DEFAULT NULL,
  PRIMARY KEY (`documentid`),
  KEY `title_index` (`title`(5)),
  KEY `bookid` (`bookid`),
  KEY `verlagid` (`verlagid`),
  KEY `seriesid` (`seriesid`),
  KEY `ownerid` (`ownerid`),
  KEY `doctypeid` (`doctypeid`),
  KEY `institutionid` (`institutionid`),
  KEY `journalid` (`journalid`),
  FULLTEXT KEY `abstract` (`abstract`)
) ENGINE=MyISAM AUTO_INCREMENT=285969 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `edits_book`
--

DROP TABLE IF EXISTS `edits_book`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `edits_book` (
  `edits_bookid` int(11) NOT NULL AUTO_INCREMENT,
  `bookid` int(11) NOT NULL DEFAULT '0',
  `authorid` int(11) NOT NULL DEFAULT '0',
  `editor_rank` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`edits_bookid`),
  KEY `bookid` (`bookid`),
  KEY `authorid` (`authorid`)
) ENGINE=MyISAM AUTO_INCREMENT=22662 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `edits_series`
--

DROP TABLE IF EXISTS `edits_series`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `edits_series` (
  `edits_seriesid` int(11) NOT NULL AUTO_INCREMENT,
  `seriesid` int(11) NOT NULL DEFAULT '0',
  `authorid` int(11) NOT NULL DEFAULT '0',
  `serieseditor_rank` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`edits_seriesid`),
  KEY `seriesid` (`seriesid`),
  KEY `authorid` (`authorid`)
) ENGINE=MyISAM AUTO_INCREMENT=1564 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `institution`
--

DROP TABLE IF EXISTS `institution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `institution` (
  `institutionid` int(11) NOT NULL AUTO_INCREMENT,
  `institution` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`institutionid`)
) ENGINE=MyISAM AUTO_INCREMENT=403 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `journal`
--

DROP TABLE IF EXISTS `journal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `journal` (
  `journalid` int(11) NOT NULL AUTO_INCREMENT,
  `journaltitle` text,
  `titlesynonym1` tinytext,
  PRIMARY KEY (`journalid`)
) ENGINE=MyISAM AUTO_INCREMENT=32648 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `keyword`
--

DROP TABLE IF EXISTS `keyword`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `keyword` (
  `keywordid` int(11) NOT NULL AUTO_INCREMENT,
  `word` char(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`keywordid`),
  KEY `keyword_index` (`word`)
) ENGINE=MyISAM AUTO_INCREMENT=109453 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `kword_in_doc`
--

DROP TABLE IF EXISTS `kword_in_doc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kword_in_doc` (
  `kword_in_docid` int(11) NOT NULL AUTO_INCREMENT,
  `documentid` int(11) NOT NULL DEFAULT '0',
  `keywordid` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`kword_in_docid`),
  KEY `documentid` (`documentid`),
  KEY `keywordid` (`keywordid`)
) ENGINE=MyISAM AUTO_INCREMENT=1036160 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `owner`
--

DROP TABLE IF EXISTS `owner`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `owner` (
  `ownerid` int(11) NOT NULL AUTO_INCREMENT,
  `name` char(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`ownerid`)
) ENGINE=MyISAM AUTO_INCREMENT=54 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `parameters`
--

DROP TABLE IF EXISTS `parameters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `parameters` (
  `sessionid` varchar(50) NOT NULL DEFAULT '',
  `action` varchar(20) NOT NULL DEFAULT '',
  `questiontext` varchar(255) DEFAULT NULL,
  `questionid` varchar(50) DEFAULT NULL,
  `frames` int(2) DEFAULT NULL,
  `databasename` varchar(20) DEFAULT NULL,
  `checked` int(1) DEFAULT NULL,
  `sorting` varchar(20) DEFAULT NULL,
  `resultpart` int(20) DEFAULT NULL,
  `fastsearch` int(1) DEFAULT NULL,
  PRIMARY KEY (`sessionid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `question`
--

DROP TABLE IF EXISTS `question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `question` (
  `questionid` varchar(50) NOT NULL DEFAULT '',
  `quser` varchar(20) DEFAULT NULL,
  `qtime` int(20) DEFAULT NULL,
  `qtext` text,
  `pid` int(11) DEFAULT NULL,
  `dataof` text,
  PRIMARY KEY (`questionid`),
  KEY `qtime` (`qtime`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `series`
--

DROP TABLE IF EXISTS `series`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `series` (
  `seriesid` int(11) NOT NULL AUTO_INCREMENT,
  `seriestitle` text NOT NULL,
  PRIMARY KEY (`seriesid`)
) ENGINE=MyISAM AUTO_INCREMENT=4491 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `species`
--

DROP TABLE IF EXISTS `species`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `species` (
  `speciesid` int(11) NOT NULL AUTO_INCREMENT,
  `speciesname` text NOT NULL,
  `speciessynonym1` tinytext,
  `speciessynonym2` tinytext,
  `speciessynonym3` tinytext,
  PRIMARY KEY (`speciesid`),
  KEY `speciesname` (`speciesname`(8))
) ENGINE=MyISAM AUTO_INCREMENT=14311 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `species_in_doc`
--

DROP TABLE IF EXISTS `species_in_doc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `species_in_doc` (
  `species_in_docid` int(11) NOT NULL AUTO_INCREMENT,
  `documentid` int(11) NOT NULL DEFAULT '0',
  `speciesid` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`species_in_docid`),
  KEY `documentid` (`documentid`),
  KEY `speciesid` (`speciesid`)
) ENGINE=MyISAM AUTO_INCREMENT=27742 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `verlag`
--

DROP TABLE IF EXISTS `verlag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `verlag` (
  `verlagid` int(11) NOT NULL AUTO_INCREMENT,
  `verlagname` text NOT NULL,
  `verlagort` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`verlagid`)
) ENGINE=MyISAM AUTO_INCREMENT=11790 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-03-12 22:02:59
