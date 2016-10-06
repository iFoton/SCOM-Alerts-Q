CREATE DATABASE [SCOMAddons]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'SCOMAddons', FILENAME = N'F:\MSSQL12.SCOM\MSSQL\DATA\SCOMAddons.mdf' , SIZE = 4096KB , MAXSIZE = 1048576KB , FILEGROWTH = 10240KB )
 LOG ON 
( NAME = N'SCOMAddons_log', FILENAME = N'F:\MSSQL12.SCOM\MSSQL\DATA\SCOMAddons_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [SCOMAddons] SET COMPATIBILITY_LEVEL = 120
GO
ALTER DATABASE [SCOMAddons] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [SCOMAddons] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [SCOMAddons] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [SCOMAddons] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [SCOMAddons] SET ARITHABORT OFF 
GO
ALTER DATABASE [SCOMAddons] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [SCOMAddons] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [SCOMAddons] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
GO
ALTER DATABASE [SCOMAddons] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [SCOMAddons] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [SCOMAddons] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [SCOMAddons] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [SCOMAddons] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [SCOMAddons] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [SCOMAddons] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [SCOMAddons] SET  DISABLE_BROKER 
GO
ALTER DATABASE [SCOMAddons] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [SCOMAddons] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [SCOMAddons] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [SCOMAddons] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [SCOMAddons] SET  READ_WRITE 
GO
ALTER DATABASE [SCOMAddons] SET RECOVERY FULL 
GO
ALTER DATABASE [SCOMAddons] SET  MULTI_USER 
GO
ALTER DATABASE [SCOMAddons] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [SCOMAddons] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [SCOMAddons] SET DELAYED_DURABILITY = DISABLED 
GO
USE [SCOMAddons]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [SCOMAddons] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO
